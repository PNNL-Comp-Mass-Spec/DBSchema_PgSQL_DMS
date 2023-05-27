--
CREATE OR REPLACE PROCEDURE sw.delete_job_if_new_or_failed
(
    _job int,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Deletes the given job from T_Jobs if the state is New, Failed, or Holding
**      Does not delete the job if it has running job steps (though if the step started over 48 hours ago, ignore that job step)
**      This procedure is called by DeleteAnalysisJob in DMS5
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _jobState int := 0;
    _skipMessage text := '';
    _jobText text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    _infoOnly := Coalesce(_infoOnly, false);

    _jobText := format('job %s', Coalesce(_job::text, '??'));

    If _infoOnly Then
        If Exists (SELECT *
                   FROM sw.t_jobs
                   WHERE job = _job AND
                         state IN (1, 5, 8) AND
                         NOT job IN ( SELECT JS.job
                                      FROM sw.t_job_steps JS
                                      WHERE JS.job = _job AND
                                            JS.state IN (4, 9) AND
                                            JS.start >= CURRENT_TIMESTAMP - Interval '48 hours') )
        Then

            ---------------------------------------------------
            -- Job deletion is allowed since state is 1, 5, or 8 (new, failed, or holding), and no running job steps
            ---------------------------------------------------
            --
            SELECT format('DMS_Pipeline job to be deleted: job %s, state %s, dataset %s', Job, state, dataset)
            INTO _message
            FROM sw.t_jobs
            WHERE job = _job;

            RAISE INFO '%', _message;
            RETURN;
        End If;

        If Exists (SELECT * FROM sw.t_jobs WHERE job = _job) Then
            SELECT state
            INTO _jobState
            FROM sw.t_jobs
            WHERE job = _job;

            If _jobState IN (2,3,9) Then
                _skipMessage := 'DMS_Pipeline job will not be deleted; job is in progress';
            ElsIf _jobState IN (4,7,14)
                _skipMessage := 'DMS_Pipeline job will not be deleted; job completed successfully';
            Else
                _skipMessage := 'DMS_Pipeline job will not be deleted; job state is not New, Failed, or Holding';
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
    -- Delete the jobs that are new, failed, or holding (job state 1, 5, or 8)
    -- Skip any jobs with running job steps that started within the last 2 days
    ---------------------------------------------------
    --
    DELETE FROM sw.t_jobs
    WHERE job = _job AND
          state IN (1, 5, 8) AND
          NOT job IN ( SELECT JS.job
                       FROM sw.t_job_steps JS
                       WHERE JS.job = _job AND
                             JS.state IN (4, 9) AND
                             JS.start >= CURRENT_TIMESTAMP - Interval '48 hours' );

    If FOUND Then
        _message := format('Deleted analysis %s from sw.t_jobs', _jobText);
        RAISE INFO '%', _message;
    Else
        If _jobState IN (2,3,9) Then
            RAISE WARNING 'Pipeline % not deleted; job is in progress', _jobText;
        ElsIf _jobState IN (4,7,14)
            RAISE WARNING 'Pipeline % not deleted; job completed successfully', _jobText;
        Else
            RAISE WARNING 'Pipeline % not deleted; job state is not New, Failed, or Holding', _jobText;
        End If;
    End If;

END
$$;

COMMENT ON PROCEDURE sw.delete_job_if_new_or_failed IS 'DeleteJobIfNewOrFailed';
