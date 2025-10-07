--
-- Name: delete_job_if_new_or_failed(integer, text, text, text, boolean); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.delete_job_if_new_or_failed(IN _job integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete the given job from sw.t_jobs if the state is New, Failed, or Holding
**      Does not delete the job if it has running job steps (though if the step started over 7 days ago, ignore that job step)
**      This procedure is called by public.delete_analysis_job()
**
**  Arguments:
**    _job          Job number to delete
**    _message      Status message
**    _returnCode   Return code
**    _callingUser  Calling user
**    _infoOnly     When true, preview the deletion (or show a message if the job would not be deleted since it does not meet the requirements)
**
**  Auth:   mem
**  Date:   04/21/2017 mem - Initial release
**          05/26/2017 mem - Check for job step state 9 (Running_Remote)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/01/2017 mem - Fix preview bug
**          09/27/2018 mem - Rename _previewMode to _infoOnly
**          05/04/2020 mem - Add additional debug messages
**          08/08/2020 mem - Customize message shown when _infoOnly = false
**          10/18/2022 mem - Fix logic bugs for warning messages
**          08/01/2023 mem - Use a 7 day threshold for ignoring running job steps (previously 48 hours)
**                         - Ported to PostgreSQL
**          09/08/2023 mem - Adjust capitalization of keywords
**          01/06/2024 mem - Select a single column when using If Exists ()
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _jobState int := 0;
    _skipMessage text;
    _jobText text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    _infoOnly := Coalesce(_infoOnly, false);

    _jobText := format('job %s', Coalesce(_job::text, '??'));

    If _infoOnly Then
        RAISE INFO '';

        _skipMessage := '';

        If Exists (SELECT job
                   FROM sw.t_jobs
                   WHERE job = _job AND
                         state IN (1, 5, 8) AND
                         job IN (SELECT JS.job
                                 FROM sw.t_job_steps JS
                                 WHERE JS.job = _job AND
                                       JS.state IN (4, 9) AND
                                       JS.start >= CURRENT_TIMESTAMP - Interval '7 days')
                  ) Then

            ---------------------------------------------------
            -- Job state is 1, 5, or 8, but it has a running job step that started within the last 7 days
            ---------------------------------------------------

            _skipMessage := 'Job will not be deleted from sw.t_jobs; it has a running job step';

        ElsIf Exists (SELECT job
                      FROM sw.t_jobs
                      WHERE job = _job AND
                            state IN (1, 5, 8) AND
                            NOT job IN (SELECT JS.job
                                        FROM sw.t_job_steps JS
                                        WHERE JS.job = _job AND
                                              JS.state IN (4, 9) AND
                                              JS.start >= CURRENT_TIMESTAMP - Interval '7 days')
                     ) Then

            ---------------------------------------------------
            -- Job deletion is allowed since state is 1, 5, or 8 (new, failed, or holding), and no running job steps
            ---------------------------------------------------

            SELECT format('Job to be deleted from sw.t_jobs: job %s, state %s, dataset %s', Job, state, dataset)
            INTO _message
            FROM sw.t_jobs
            WHERE job = _job;

            RAISE INFO '%', _message;
            RETURN;
        End If;

        If Exists (SELECT job FROM sw.t_jobs WHERE job = _job) Then
            SELECT state
            INTO _jobState
            FROM sw.t_jobs
            WHERE job = _job;

            If _skipMessage = '' Then
                If _jobState In (2, 3, 9) Then
                    _skipMessage := 'Job will not be deleted from sw.t_jobs; job is in progress';
                ElsIf _jobState In (4, 7, 14) Then
                    _skipMessage := 'Job will not be deleted from sw.t_jobs; job completed successfully';
                Else
                    _skipMessage := 'Job will not be deleted from sw.t_jobs; job state is not New, Failed, or Holding';
                End If;
            End If;

            SELECT format('%s: job %s, state %s, dataset %s', _skipMessage, Job, state, dataset)
            INTO _message
            FROM sw.t_jobs
            WHERE job = _job;

            RAISE WARNING '%', _message;
            RETURN;
        End If;

        RAISE WARNING 'Job not found in sw.t_jobs: %', _job;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Delete the job if new, failed, or holding (job state 1, 5, or 8)
    -- Skip any jobs with running job steps that started within the last 7 days
    ---------------------------------------------------

    DELETE FROM sw.t_jobs
    WHERE job = _job AND
          state IN (1, 5, 8) AND
          NOT job IN (SELECT JS.job
                      FROM sw.t_job_steps JS
                      WHERE JS.job = _job AND
                            JS.state IN (4, 9) AND
                            JS.start >= CURRENT_TIMESTAMP - Interval '7 days');

    If FOUND Then
        _message := format('Deleted analysis %s from sw.t_jobs', _jobText);
        RAISE INFO '%', _message;
        RETURN;
    End If;

    If Not Exists (SELECT job FROM sw.t_jobs WHERE job = _job) Then
        RAISE WARNING 'Job not found in sw.t_jobs: %', _job;
        RETURN;
    End If;

    If _jobState In (2, 3, 9) Or Exists (SELECT JS.job
                                         FROM sw.t_job_steps JS
                                         WHERE JS.job = _job AND
                                               JS.state IN (4, 9) AND
                                               JS.start >= CURRENT_TIMESTAMP - Interval '7 days')
    Then
        RAISE WARNING 'Pipeline % not deleted; job is in progress', _jobText;
    ElsIf _jobState IN (4,7,14) Then
        RAISE WARNING 'Pipeline % not deleted; job completed successfully', _jobText;
    Else
        RAISE WARNING 'Pipeline % not deleted; job state is not New, Failed, or Holding', _jobText;
    End If;
END
$$;


ALTER PROCEDURE sw.delete_job_if_new_or_failed(IN _job integer, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_job_if_new_or_failed(IN _job integer, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _infoonly boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.delete_job_if_new_or_failed(IN _job integer, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _infoonly boolean) IS 'DeleteJobIfNewOrFailed';

