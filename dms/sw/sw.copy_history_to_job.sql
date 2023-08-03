--
-- Name: copy_history_to_job(integer, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.copy_history_to_job(IN _job integer, IN _debugmode boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      For a given job, copies the job details, steps, and parameters
**      from the most recent successful job in the history tables back into the main tables
**
**  Arguments:
**    _job          Job number
**    _message      Status message
**    _returnCode   Return code
**    _debugMode    When true, show additional status messages
**
**  Auth:   grk
**  Date:   02/06/2009 grk - Initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          10/05/2009 mem - Now looking up CPU_Load for each step tool
**          04/05/2011 mem - Now copying column Special_Processing
**          05/19/2011 mem - Now calling Update_Job_Parameters
**          05/25/2011 mem - Removed priority column from T_Job_Steps
**          07/12/2011 mem - Now calling Validate_Job_Server_Info
**          10/17/2011 mem - Added column Memory_Usage_MB
**          11/01/2011 mem - Added column Tool_Version_ID
**          11/14/2011 mem - Added column Transfer_Folder_Path
**          01/09/2012 mem - Added column Owner
**          01/19/2012 mem - Added column DataPkgID
**          03/26/2013 mem - Added column Comment
**          12/10/2013 mem - Added support for failed jobs
**          01/20/2014 mem - Added T_Job_Step_Dependencies_History
**          01/21/2014 mem - Added support for jobs that don't have cached dependencies in T_Job_Step_Dependencies_History
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          03/10/2015 mem - Now adding default dependencies if a similar job cannot be found
**          03/10/2015 mem - Now updating T_Job_Steps.Dependencies if it doesn't match the dependent steps listed in T_Job_Step_Dependencies
**          11/18/2015 mem - Add Actual_CPU_Load
**          05/12/2017 mem - Add Remote_Info_ID
**          01/19/2018 mem - Add Runtime_Minutes
**          07/25/2019 mem - Add Remote_Start and Remote_Finish
**          07/31/2023 mem - Ported to PostgreSQL
**          08/02/2023 mem - Move the _message and _returnCode arguments to the end of the argument list
**
*****************************************************/
DECLARE
    _currentLocation text := 'Start';
    _dateStamp timestamp;
    _jobDateDescription text;
    _similarJob int;
    _jobList text;
    _insertCount int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _debugMode := Coalesce(_debugMode, false);

    ---------------------------------------------------
    -- Bail if no candidates found
    ---------------------------------------------------

    If Coalesce(_job, 0) = 0 Then
        _message := 'Job number is 0 or null; nothing to do';
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    If _debugMode Then
        RAISE INFO '';
        RAISE INFO 'Looking for job % in the history tables', _job;
    End If;

    ---------------------------------------------------
    -- Bail if job already exists in main tables
    ---------------------------------------------------

    If Exists (SELECT job FROM sw.t_jobs WHERE job = _job) Then
        _message := format('Job %s already exists in sw.t_jobs; aborting', _job);
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Get job status from most recent completed historic job
    ---------------------------------------------------

    -- Find most recent successful historic job
    --
    SELECT MAX(saved)
    INTO _dateStamp
    FROM sw.t_jobs_history
    WHERE job = _job AND state = 4;

    If Not FOUND Then
        RAISE INFO 'No successful jobs found in sw.t_jobs_history for job %; will look for a failed job', _job;

        -- Find most recent historic job, regardless of job state
        --
        SELECT MAX(saved)
        INTO _dateStamp
        FROM sw.t_jobs_history
        WHERE job = _job;

        If Not FOUND Then
            _message := format('Job not found in sw.t_jobs_history: %s', _job);
            RAISE WARNING '%', _message;

            RETURN;
        End If;

        RAISE INFO 'Match found, saved on %', public.timestamp_text(_dateStamp);

    End If;

    BEGIN
        _jobDateDescription := format('job %s and date %s', _job, _dateStamp);

        _currentLocation := format('Insert into sw.t_jobs from sw.t_jobs_history for %s', _jobDateDescription);

        INSERT INTO sw.t_jobs( job,
                               priority,
                               script,
                               state,
                               dataset,
                               dataset_id,
                               results_folder_name,
                               organism_db_name,
                               special_processing,
                               imported,
                               start,
                               finish,
                               runtime_minutes,
                               transfer_folder_path,
                               owner_username,
                               data_pkg_id,
                               Comment )
        SELECT job,
               priority,
               script,
               state,
               dataset,
               dataset_id,
               results_folder_name,
               organism_db_name,
               special_processing,
               imported,
               start,
               finish,
               runtime_minutes,
               transfer_folder_path,
               owner_username,
               data_pkg_id,
               Comment
        FROM sw.t_jobs_history
        WHERE job = _job AND
              saved = _dateStamp;

        If Not FOUND Then
            _message := format('No rows were added to sw.t_jobs from sw.t_jobs_history for %s', _jobDateDescription);
            RAISE WARNING '%', _message;

            RETURN;
        End If;

        RAISE INFO 'Added job % to sw.t_jobs', _job;

        ---------------------------------------------------
        -- Copy job steps
        ---------------------------------------------------

        _currentLocation := format('Insert into sw.t_job_steps for %s', _jobDateDescription);

        INSERT INTO sw.t_job_steps( job,
                                    step,
                                    tool,
                                    cpu_load,
                                    actual_cpu_load,
                                    memory_usage_mb,
                                    shared_result_version,
                                    signature,
                                    state,
                                    input_folder_name,
                                    output_folder_name,
                                    processor,
                                    start,
                                    finish,
                                    tool_version_id,
                                    completion_code,
                                    completion_message,
                                    evaluation_code,
                                    evaluation_message,
                                    remote_info_id,
                                    remote_start,
                                    remote_finish )
        SELECT H.job,
               H.step,
               H.tool,
               ST.cpu_load,
               ST.cpu_load,
               H.memory_usage_mb,
               H.shared_result_version,
               H.signature,
               H.state,
               H.input_folder_name,
               H.output_folder_name,
               H.processor,
               H.start,
               H.finish,
               H.tool_version_id,
               H.completion_code,
               H.completion_message,
               H.evaluation_code,
               H.evaluation_message,
               H.remote_info_id,
               H.remote_start,
               H.remote_finish
        FROM sw.t_job_steps_history H
             INNER JOIN sw.t_step_tools ST
               ON H.tool = ST.step_tool
        WHERE H.job = _job AND
              H.saved = _dateStamp;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        If _debugMode Then
            RAISE INFO 'Inserted % steps into sw.t_job_steps for %', _insertCount, _jobDateDescription;
        End If;

        -- Change any waiting, enabled, or running steps to state 7 (holding)
        -- This is a safety feature to avoid job steps from starting inadvertently
        --
        UPDATE sw.t_job_steps
        SET state = 7
        WHERE job = _job AND
              state IN (1, 2, 4, 9);

        ---------------------------------------------------
        -- Copy parameters
        ---------------------------------------------------

        _currentLocation := format('Insert into sw.t_job_parameters for %s', _jobDateDescription);

        INSERT INTO sw.t_job_parameters( job, parameters )
        SELECT job,
               parameters
        FROM sw.t_job_parameters_history
        WHERE job = _job AND
              saved = _dateStamp;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        If _debugMode Then
            RAISE INFO 'Inserted % row into sw.t_job_parameters for %', _insertCount, _jobDateDescription;
        End If;

        ---------------------------------------------------
        -- Copy job step dependencies
        ---------------------------------------------------

        _currentLocation := format('Insert into sw.t_job_step_dependencies for %s', _jobDateDescription);

        -- First delete any extra steps for this job that are in sw.t_job_step_dependencies
        --
        DELETE FROM sw.t_job_step_dependencies target
        WHERE EXISTS
            (  SELECT 1
               FROM sw.t_job_step_dependencies TSD
                    INNER JOIN ( SELECT JSD.Job,
                                        JSD.Step
                                 FROM sw.t_job_step_dependencies JSD
                                      LEFT OUTER JOIN sw.t_job_step_dependencies_history H
                                        ON JSD.Job = H.Job AND
                                           JSD.Step = H.Step AND
                                           JSD.Target_Step = H.Target_Step
                                 WHERE JSD.Job = _job AND
                                       H.Job IS NULL
                                ) DeleteQ
                      ON TSD.Job = DeleteQ.Job AND
                         TSD.Step = DeleteQ.Step
                WHERE target.job = TSD.job AND
                      target.step = TSD.step
            );


        -- Check whether this job has entries in sw.t_job_step_dependencies_history
        --
        If Not Exists (SELECT job FROM sw.t_job_step_dependencies_history WHERE job = _job) Then
            -- Job did not have cached dependencies
            -- Look for a job that used the same script

            SELECT MIN(H.job)
            INTO _similarJob
            FROM sw.t_job_step_dependencies_history H
                 INNER JOIN ( SELECT job
                              FROM sw.t_jobs_history
                              WHERE job > _job AND
                                    script = ( SELECT script
                                               FROM sw.t_jobs_history
                                               WHERE job = _job AND
                                                     most_recent_entry = 1 )
                             ) SimilarJobQ
                   ON H.job = SimilarJobQ.job;

            If FOUND Then
                If _debugMode Then
                    RAISE INFO 'Insert Into sw.t_job_step_dependencies using model job %', _similarJob;
                End If;

                INSERT INTO sw.t_job_step_dependencies( job,
                                                        step,
                                                        target_step,
                                                        condition_test,
                                                        test_value,
                                                        evaluated,
                                                        triggered,
                                                        enable_only )
                SELECT _job AS Job,
                       step,
                       target_step,
                       condition_test,
                       test_value,
                       0 AS Evaluated,
                       0 AS Triggered,
                       enable_only
                FROM sw.t_job_step_dependencies_history H
                WHERE job = _similarJob;
                --
                GET DIAGNOSTICS _insertCount = ROW_COUNT;

                If _debugMode Then
                    RAISE INFO 'Added % rows to sw.t_job_step_dependencies_history for % using model job %', _insertCount, _jobDateDescription, _similarJob;
                End If;

            Else
                -- No similar jobs
                -- Create default dependencenies

                If _debugMode Then
                    RAISE INFO 'Create default dependencies for job %', _job;
                End If;

                INSERT INTO sw.t_job_step_dependencies( job,
                                                        step,
                                                        target_step,
                                                        evaluated,
                                                        triggered,
                                                        enable_only )
                SELECT job,
                       step,
                       step - 1 AS Target_Step,
                       0 AS Evaluated,
                       0 AS Triggered,
                       0 AS Enable_Only
                FROM sw.t_job_steps
                WHERE job = _job AND
                      step > 1;
                --
                GET DIAGNOSTICS _insertCount = ROW_COUNT;

                If _debugMode Then
                    RAISE INFO 'Added % rows to sw.t_job_step_dependencies for %', _insertCount, _jobDateDescription;
                End If;
            End If;

        Else

            If _debugMode Then
                RAISE INFO 'Insert into sw.t_job_step_dependencies using sw.t_task_step_dependencies_history for %', _jobDateDescription;
            End If;

            -- Now add/update the job step dependencies
            --
            INSERT INTO sw.t_job_step_dependencies (job, Step, Target_Step, condition_test, test_value, evaluated, triggered, enable_only)
            SELECT job,
                   step,
                   target_step,
                   condition_test,
                   test_value,
                   evaluated,
                   triggered,
                   enable_only
            FROM sw.t_job_step_dependencies_history
            WHERE job = _job
            ON CONFLICT (job, step, target_step)
            DO UPDATE SET
                    condition_test = EXCLUDED.condition_test,
                    test_value = EXCLUDED.test_value,
                    evaluated = EXCLUDED.evaluated,
                    triggered = EXCLUDED.triggered,
                    enable_only = EXCLUDED.enable_only;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation, _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        RETURN;
    END;

    ---------------------------------------------------
    -- Update the job parameters in case any parameters have changed (in particular, storage path)
    ---------------------------------------------------

    CALL sw.update_job_parameters (
                _job,
                _infoOnly => false,
                _settingsFileOverride => '',
                _message => _message,
                _returnCode => _returnCode);

    ---------------------------------------------------
    -- Make sure transfer_folder_path and storage_server are up-to-date in sw.t_jobs
    ---------------------------------------------------

    CALL sw.validate_job_server_info (
                _job,
                _useJobParameters => true,
                _debugMode => _debugMode,
                _message => _message,           -- Output
                _returnCode => _returnCode      -- Output
                );

    ---------------------------------------------------
    -- Make sure the dependencies column is up-to-date in sw.t_job_steps
    ---------------------------------------------------

    UPDATE sw.t_job_steps target
    SET dependencies = CountQ.dependencies
    FROM ( SELECT step,
                  COUNT(target_step) AS dependencies
           FROM sw.t_job_step_dependencies
           WHERE job = _job
           GROUP BY step
         ) CountQ
    WHERE target.Job = _job AND
          CountQ.Step = target.Step AND
          CountQ.Dependencies > target.Dependencies;

   _message := format('Copied job %s from the history tables to the active job tables', _job);

    If _debugMode Then
        RAISE INFO '%', _message;
    End If;
END
$$;


ALTER PROCEDURE sw.copy_history_to_job(IN _job integer, IN _debugmode boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE copy_history_to_job(IN _job integer, IN _debugmode boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.copy_history_to_job(IN _job integer, IN _debugmode boolean, INOUT _message text, INOUT _returncode text) IS 'CopyHistoryToJob';

