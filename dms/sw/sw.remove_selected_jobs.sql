--
-- Name: remove_selected_jobs(boolean, text, text, boolean, boolean); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.remove_selected_jobs(IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _logdeletions boolean DEFAULT false, IN _logtoconsoleonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Remove specified jobs from sw.t_jobs, sw.t_job_steps, etc.
**      The list of jobs to delete is read from temporary table Tmp_Selected_Jobs (created and populated by the caller)
**
**          CREATE TEMP TABLE Tmp_Selected_Jobs (
**              Job int,
**              State int
**          );
**
**  Arguments:
**    _infoOnly             When true, don't actually delete, just display the list of jobs that would be deleted
**    _message              Status message
**    _returnCode           Return code
**    _logDeletions         When true, logs each deleted job number to sw.t_log_entries (but only if _logToConsoleOnly is false)
**    _logToConsoleOnly     When _logDeletions is true, optionally set this to true to only show deleted job info in the output console (via RAISE INFO messages)
**
**  Auth:   grk
**  Date:   02/19/2009 grk - Initial release (Ticket #723)
**          02/26/2009 mem - Added parameter _logDeletions
**          02/28/2009 grk - Added logic to preserve record of successful shared results
**          08/20/2013 mem - Added support for _logToConsoleOnly
**                         - Now disabling trigger trig_ud_T_Jobs when deleting rows from T_Jobs (required because procedure RemoveOldJobs wraps the call to this procedure with a transaction)
**          06/16/2014 mem - Now disabling trigger trig_ud_T_Job_Steps when deleting rows from T_Job_Steps
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          06/29/2023 mem - Ported to PostgreSQL
**          08/08/2023 mem - Store the deletion count summary in _message
**
*****************************************************/
DECLARE
    _job int;
    _jobCount int;
    _deleteCount int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    _infoOnly := Coalesce(_infoOnly, false);
    _logDeletions := Coalesce(_logDeletions, false);
    _logToConsoleOnly := Coalesce(_logToConsoleOnly, false);

    ---------------------------------------------------
    -- Bail if no candidates found
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _jobCount
    FROM Tmp_Selected_Jobs;

    If _jobCount = 0 Then
        RETURN;
    End If;

    If _infoOnly Then

        ---------------------------------------------------
        -- Preview the jobs to be deleted
        ---------------------------------------------------

        RAISE INFO '';
        RAISE INFO 'Previewing the % % that would be deleted', _jobCount, public.check_plural(_jobCount, 'job', 'jobs');
        RAISE INFO '';

        _formatSpecifier := '%-10s %-10s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'State'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '----------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Job, State
            FROM Tmp_Selected_Jobs
            ORDER BY Job
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Job,
                                _previewData.State
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Preserve record of successfully completed
    -- shared results
    ---------------------------------------------------

    -- For the jobs being deleted, finds all instances of
    -- successfully completed results transfer steps that
    -- were directly dependent upon steps that generated
    -- shared results, and makes sure that their output folder
    -- name is entered into the shared results table

    INSERT INTO sw.t_shared_results (results_name)
    SELECT DISTINCT JS.output_folder_name
    FROM sw.t_job_steps AS TransferJS
         INNER JOIN sw.t_job_step_dependencies AS JSD
           ON TransferJS.Job = JSD.Job AND
              TransferJS.Step = JSD.Step
         INNER JOIN sw.t_job_steps AS JS
           ON JSD.Job = JS.Job AND
              JSD.Target_Step = JS.Step
    WHERE TransferJS.Tool = 'Results_Transfer' AND
          TransferJS.state = 5 AND
          JS.shared_result_version > 0 AND
          NOT JS.output_folder_name IN ( SELECT results_name
                                         FROM sw.t_shared_results ) AND
          TransferJS.job IN ( SELECT job
                              FROM Tmp_Selected_Jobs );

    ---------------------------------------------------
    -- Delete job dependencies
    ---------------------------------------------------

    DELETE FROM sw.t_job_step_dependencies
    WHERE job IN (SELECT job FROM Tmp_Selected_Jobs);
    --
    GET DIAGNOSTICS _deleteCount = ROW_COUNT;

    If _logDeletions Then
        RAISE INFO '';
        RAISE INFO 'Deleted % % from sw.t_job_step_dependencies', _deleteCount, public.check_plural(_deleteCount, 'row', 'rows');
    End If;

    ---------------------------------------------------
    -- Delete job parameters
    ---------------------------------------------------

    DELETE FROM sw.t_job_parameters
    WHERE job IN (SELECT job FROM Tmp_Selected_Jobs);
    --
    GET DIAGNOSTICS _deleteCount = ROW_COUNT;

    If _logDeletions Then
        RAISE INFO 'Deleted % % from sw.t_job_parameters', _deleteCount, public.check_plural(_deleteCount, 'row', 'rows');
    End If;

    ALTER TABLE sw.t_job_steps DISABLE TRIGGER trig_t_job_steps_after_delete;

    ---------------------------------------------------
    -- Delete job steps
    ---------------------------------------------------

    DELETE FROM sw.t_job_steps
    WHERE job IN (SELECT job FROM Tmp_Selected_Jobs);
    --
    GET DIAGNOSTICS _deleteCount = ROW_COUNT;

    If _logDeletions Then
        RAISE INFO 'Deleted % % from sw.t_job_steps', _deleteCount, public.check_plural(_deleteCount, 'row', 'rows');
    End If;

    ALTER TABLE sw.t_job_steps ENABLE TRIGGER trig_t_job_steps_after_delete;

    ---------------------------------------------------
    -- Delete entries in sw.t_jobs
    ---------------------------------------------------

    If _logDeletions And Not _logToConsoleOnly Then

        ---------------------------------------------------
        -- Delete jobs one at a time, posting a log entry for each deleted job
        ---------------------------------------------------

        _deleteCount := 0;

        FOR _job IN
            SELECT Job
            FROM Tmp_Selected_Jobs
            ORDER BY Job
        LOOP

            DELETE FROM sw.t_jobs
            WHERE job = _job;

            If FOUND Then
                _message := format('Deleted job %s from sw.t_jobs', _job);
                CALL public.post_log_entry ('Normal', _message, 'Remove_Selected_Jobs', 'sw');
                _deleteCount := _deleteCount + 1;
            Else
                RAISE INFO 'Job % already deleted from sw.t_jobs', _job;
            End If;

        END LOOP;

        _message := format('Deleted %s %s from sw.t_jobs', _deleteCount, public.check_plural(_deleteCount, 'row', 'rows'));

        RAISE INFO '%', _message;

    Else

        ---------------------------------------------------
        -- Delete in bulk
        ---------------------------------------------------

        ALTER TABLE sw.t_jobs DISABLE TRIGGER trig_t_jobs_after_delete;

        DELETE FROM sw.t_jobs
        WHERE job IN (SELECT job FROM Tmp_Selected_Jobs);
        --
        GET DIAGNOSTICS _deleteCount = ROW_COUNT;

        _message := format('Deleted %s %s from sw.t_jobs', _deleteCount, public.check_plural(_deleteCount, 'row', 'rows'));

        If _logDeletions Then
            RAISE INFO '%', _message;
        End If;

        ALTER TABLE sw.t_jobs ENABLE TRIGGER trig_t_jobs_after_delete;

    End If;

END
$$;


ALTER PROCEDURE sw.remove_selected_jobs(IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _logdeletions boolean, IN _logtoconsoleonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE remove_selected_jobs(IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _logdeletions boolean, IN _logtoconsoleonly boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.remove_selected_jobs(IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _logdeletions boolean, IN _logtoconsoleonly boolean) IS 'RemoveSelectedJobs';

