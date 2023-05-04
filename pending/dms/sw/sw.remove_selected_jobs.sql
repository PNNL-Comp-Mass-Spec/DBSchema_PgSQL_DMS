--
CREATE OR REPLACE PROCEDURE sw.remove_selected_jobs
(
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _logDeletions boolean = false,
    _logToConsoleOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Delete jobs given in temp table Tmp_SJL, which must be populated by the caller
**
**          CREATE TEMP TABLE Tmp_SJL (
**              Job int,
**              State int
**          );
**
**  Arguments:
**    _infoOnly             When true, don't actually delete, just dump list of jobs that would have been
**    _logDeletions         When true, logs each deleted job number to T_Log_Entries (but only if _logToConsoleOnly is false)
**    _logToConsoleOnly     When _logDeletions is true, optionally set this to true to only show deleted job info in the output console (via RAISE INFO messages)
**
**  Auth:   grk
**  Date:   02/19/2009 grk - initial release (Ticket #723)
**          02/26/2009 mem - Added parameter _logDeletions
**          02/28/2009 grk - Added logic to preserve record of successful shared results
**          08/20/2013 mem - Added support for _logToConsoleOnly
**                         - Now disabling trigger trig_ud_T_Jobs when deleting rows from T_Jobs (required because procedure RemoveOldJobs wraps the call to this procedure with a transaction)
**          06/16/2014 mem - Now disabling trigger trig_ud_T_Job_Steps when deleting rows from T_Job_Steps
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _job int;
    _numJobs int;
BEGIN
    _message := '';
    _returnCode:= '';

    _infoOnly := Coalesce(_infoOnly, false);
    _logDeletions := Coalesce(_logDeletions, false);
    _logToConsoleOnly := Coalesce(_logToConsoleOnly, false);

    ---------------------------------------------------
    -- Bail If no candidates found
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _numJobs
    FROM Tmp_SJL;

    If _numJobs = 0 Then
        RETURN;
    End If;

    If _infoOnly Then
        -- ToDo: Show the contents of Tmp_SJL using RAISE INFO
        SELECT * FROM Tmp_SJL;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Preserve record of successfully completed
    -- shared results
    ---------------------------------------------------
    --
    -- For the jobs being deleted, finds all instances of
    -- successfully completed results transfer steps that
    -- were directly dependent upon steps that generated
    -- shared results, and makes sure that their output folder
    -- name is entered into the shared results table
    --
    INSERT INTO sw.t_shared_results( results_name )
    SELECT DISTINCT JS.output_folder_name
    FROM sw.t_job_steps AS JS
        INNER JOIN sw.t_job_step_dependencies AS JSD
          ON JS.Job = JSD.Job AND
             JS.Step = JSD.Step
        INNER JOIN sw.t_job_steps AS JS
          ON JSD.Job = JS.Job AND
             JSD.Target_Step = JS.Step
    WHERE JS.Tool = 'Results_Transfer' AND
          JS.state = 5 AND
          JS.shared_result_version > 0 AND
          NOT JS.output_folder_name IN ( SELECT results_name
                                         FROM sw.t_shared_results ) AND
          JS.job IN ( SELECT job
                      FROM Tmp_SJL );

    ---------------------------------------------------
    -- Delete job dependencies
    ---------------------------------------------------
    --
    DELETE FROM sw.t_job_step_dependencies
    WHERE (job IN (SELECT job FROM Tmp_SJL));
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _logDeletions Then
        RAISE INFO '%', 'Deleted ' || _myRowCount::text || ' rows from sw.t_job_step_dependencies';
    End If;

    ---------------------------------------------------
    -- Delete job parameters
    ---------------------------------------------------
    --
    DELETE FROM sw.t_job_parameters
    WHERE job IN (SELECT job FROM Tmp_SJL)
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _logDeletions Then
        RAISE INFO '%', 'Deleted ' || _myRowCount::text || ' rows from sw.t_job_parameters';
    End If;

    disable trigger trig_ud_T_Job_Steps on sw.t_job_steps;

    ---------------------------------------------------
    -- Delete job steps
    ---------------------------------------------------
    --
    DELETE FROM sw.t_job_steps
    WHERE job IN (SELECT job FROM Tmp_SJL)
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _logDeletions Then
        RAISE INFO '%', 'Deleted ' || _myRowCount::text || ' rows from sw.t_job_steps';
    End If;

    enable trigger trig_ud_T_Job_Steps on sw.t_job_steps;

    ---------------------------------------------------
    -- Delete entries in sw.t_jobs
    ---------------------------------------------------
    --
    If _logDeletions And Not _logToConsoleOnly Then

        ---------------------------------------------------
        -- Delete jobs one at a time, posting a log entry for each deleted job
        ---------------------------------------------------

        FOR _job IN
            SELECT Job
            FROM Tmp_SJL
            ORDER BY Job
        LOOP

            DELETE FROM sw.t_jobs
            WHERE job = _job;

            _message := 'Deleted job ' || _job::text || ' from sw.t_jobs';
            Call public.post_log_entry ('Normal', _message, 'Remove_Selected_Jobs', 'sw');

        END LOOP;

    Else

        ---------------------------------------------------
        -- Delete in bulk
        ---------------------------------------------------

        Disable Trigger trig_ud_T_Jobs ON sw.t_jobs;

        DELETE FROM sw.t_jobs
        WHERE job IN (SELECT job FROM Tmp_SJL)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _logDeletions Then
            RAISE INFO '%', 'Deleted ' || _myRowCount::text || ' rows from sw.t_jobs';
        End If;

        Enable Trigger trig_ud_T_Jobs ON sw.t_jobs;

    End If;

END
$$;

COMMENT ON PROCEDURE sw.remove_selected_jobs IS 'RemoveSelectedJobs';
