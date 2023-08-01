--
-- Name: copy_history_to_job_multi(text, boolean, text, text, boolean); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.copy_history_to_job_multi(IN _joblist text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _debugmode boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      For a list of jobs, copies the job details, steps, and parameters
**      from the most recent successful jobs in the history tables back into the main tables
**
**  Arguments:
**    _jobList      Comma-separated list of job numbers
**    _infoOnly     If true, preview the jobs that would be copied
**    _message      Status message
**    _returnCode   Return code
**    _debugMode    When true, show additional status messages

**  Auth:   mem
**  Date:   09/27/2012 mem - Initial version
**          03/26/2013 mem - Added column Comment
**          01/20/2014 mem - Added T_Job_Step_Dependencies_History
**          01/21/2014 mem - Added support for jobs that don't have cached dependencies in T_Job_Step_Dependencies_History
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          01/19/2015 mem - Fix ambiguous column reference
**          11/18/2015 mem - Add Actual_CPU_Load
**          02/23/2016 mem - Add Set XACT_ABORT on
**          05/12/2017 mem - Add Remote_Info_ID
**          01/19/2018 mem - Add Runtime_Minutes
**          06/20/2018 mem - Move rollback transaction to before the call to Local_Error_Handler
**          07/25/2019 mem - Add Remote_Start and Remote_Finish
**          07/31/2023 mem - Make sure the dependencies column is up-to-date in t_job_steps
**                         - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentLocation text := 'Start';
    _jobCount int;
    _jobDateDescription text;
    _deleteCount int;
    _insertCount int;

    _job int := 0;
    _jobsCopied int := 0;
    _jobsRefreshed int := 0;
    _lastStatusTime timestamp := CURRENT_TIMESTAMP;
    _progressMsg text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _debugMode := Coalesce(_debugMode, false);

    ---------------------------------------------------
    -- Populate a temporary table with the jobs in _jobList
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_JobsToCopy (
        Job int NOT NULL,
        DateStamp timestamp NULL
    );

    CREATE INDEX IX_Tmp_JobsToCopy ON Tmp_JobsToCopy (Job);

    INSERT INTO Tmp_JobsToCopy (Job)
    SELECT Value
    FROM public.parse_delimited_integer_list(_jobList, ',');

    ---------------------------------------------------
    -- Bail if no candidates found
    ---------------------------------------------------

    If Not Exists (SELECT * FROM Tmp_JobsToCopy) Then
        _message := '_jobList was empty or contained no jobs';
        RAISE INFO '%', _message;

        DROP TABLE Tmp_JobsToCopy;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Remove jobs that already exist in sw.t_jobs
    ---------------------------------------------------

    DELETE FROM Tmp_JobsToCopy
    WHERE job IN (SELECT job FROM sw.t_jobs);

    ---------------------------------------------------
    -- Bail if no candidates found
    ---------------------------------------------------

    If Not Exists (SELECT * FROM Tmp_JobsToCopy) Then
        _message := 'All jobs in _jobList already exist in sw.t_jobs';
        RAISE INFO '%', _message;

        DROP TABLE Tmp_JobsToCopy;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Delete jobs not present in sw.t_jobs_history
    ---------------------------------------------------

    DELETE FROM Tmp_JobsToCopy
    WHERE NOT job IN (SELECT job FROM sw.t_jobs_history);

    ---------------------------------------------------
    -- Bail if no candidates remain
    ---------------------------------------------------

    If Not Exists (SELECT * FROM Tmp_JobsToCopy) Then
        _message := 'None of the jobs in _jobList exists in sw.t_jobs_history';
        RAISE INFO '%', _message;

        DROP TABLE Tmp_JobsToCopy;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Lookup the max saved date for each job
    ---------------------------------------------------

    UPDATE Tmp_JobsToCopy
    SET DateStamp = DateQ.MostRecentDate
    FROM ( SELECT JH.job,
                  MAX(JH.saved) AS MostRecentDate
           FROM sw.t_jobs_history JH
                INNER JOIN Tmp_JobsToCopy Src
                  ON JH.job = Src.job
           WHERE state = 4
           GROUP BY JH.job ) DateQ
    WHERE Tmp_JobsToCopy.job = DateQ.job;

    ---------------------------------------------------
    -- Remove jobs where DateStamp is null
    ---------------------------------------------------

    DELETE FROM Tmp_JobsToCopy
    WHERE DateStamp Is Null;
    --
    GET DIAGNOSTICS _deleteCount = ROW_COUNT;

    If _deleteCount > 0 Then
        RAISE INFO 'Deleted % % from _jobList because they do not exist in sw.t_jobs_history with state 4', _deleteCount, public.check_plural(_deleteCount, 'job', 'jobs');
    End If;

    SELECT string_agg(job::text, ', ' ORDER BY Job)
    INTO _jobList
    FROM Tmp_JobsToCopy;

    SELECT COUNT(*)
    INTO _jobCount
    FROM Tmp_JobsToCopy;

    If _infoOnly Then
        RAISE INFO '% to copy from sw.t_jobs_history to sw.t_jobs: %', public.check_plural(_jobCount, 'Job', 'Jobs'), _jobList;

        DROP TABLE Tmp_JobsToCopy;
        RETURN;
    End If;

    BEGIN
        _jobDateDescription := format('%s %s', public.check_plural(_jobCount, 'job', 'jobs'), _jobList);

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
        SELECT JH.job,
               JH.priority,
               JH.script,
               JH.state,
               JH.dataset,
               JH.dataset_id,
               JH.results_folder_name,
               JH.organism_db_name,
               JH.special_processing,
               JH.imported,
               JH.start,
               JH.finish,
               JH.runtime_minutes,
               JH.transfer_folder_path,
               JH.owner_username,
               JH.data_pkg_id,
               JH.Comment
        FROM sw.t_jobs_history JH
             INNER JOIN Tmp_JobsToCopy Src
               ON JH.job = Src.job AND
                  JH.saved = Src.DateStamp;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        If _insertCount = 0 Then
            _message := format('No rows were added to sw.t_jobs from sw.t_jobs_history for %s', _jobDateDescription);
            RAISE WARNING '%', _message;

            DROP TABLE Tmp_JobsToCopy;
            RETURN;
        End If;

        RAISE INFO 'Added % % to sw.t_jobs', _insertCount, public.check_plural(_insertCount, 'job', 'jobs');

        _jobsCopied := _insertCount;

        ---------------------------------------------------
        -- Copy job steps
        ---------------------------------------------------

        _currentLocation := 'Populate sw.t_job_steps';

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
             INNER JOIN Tmp_JobsToCopy Src
               ON H.job = Src.job AND
                  H.saved = Src.DateStamp;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        If _debugMode Then
            RAISE INFO '';
            RAISE INFO 'Inserted % % into sw.t_job_steps for %', _insertCount, public.check_plural(_insertCount, 'step', 'steps'), _jobDateDescription;
        End If;

        -- Change any waiting, enabled, or running steps to state 7 (holding)
        -- This is a safety feature to avoid job steps from starting inadvertently
        --
        UPDATE sw.t_job_steps Target
        SET state = 7
        FROM Tmp_JobsToCopy Src
        WHERE Src.Job = Target.Job AND
              Target.State IN (1, 2, 4, 9);

        ---------------------------------------------------
        -- Copy parameters
        ---------------------------------------------------

        _currentLocation := format('Insert into sw.t_job_parameters for %s', _jobDateDescription);

        INSERT INTO sw.t_job_parameters( job, parameters )
        SELECT JPH.job,
               JPH.parameters
        FROM sw.t_job_parameters_history JPH
             INNER JOIN Tmp_JobsToCopy Src
               ON JPH.job = Src.job AND
                  JPH.saved = Src.DateStamp;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        If _debugMode Then
            RAISE INFO 'Inserted % % into sw.t_job_parameters for %', _insertCount, public.check_plural(_insertCount, 'row', 'rows'), _jobDateDescription;
        End If;

        ---------------------------------------------------
        -- Copy job step dependencies
        ---------------------------------------------------

        _currentLocation := format('Insert into sw.t_job_step_dependencies for %s', _jobDateDescription);

        -- First delete any extra steps that are in sw.t_job_step_dependencies
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
                                 WHERE JSD.Job IN ( SELECT job FROM Tmp_JobsToCopy ) AND
                                       H.Job IS NULL
                                ) DeleteQ
                      ON TSD.Job = DeleteQ.Job AND
                         TSD.Step = DeleteQ.Step
                WHERE target.job = TSD.job AND
                      target.step = TSD.step
            );

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
        WHERE job IN ( SELECT job FROM Tmp_JobsToCopy )
        ON CONFLICT (job, step, target_step)
        DO UPDATE SET
                condition_test = EXCLUDED.condition_test,
                test_value = EXCLUDED.test_value,
                evaluated = EXCLUDED.evaluated,
                triggered = EXCLUDED.triggered,
                enable_only = EXCLUDED.enable_only;

        ---------------------------------------------------
        -- Fill in the dependencies for jobs that didn't have any data in sw.t_job_step_dependencies
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_JobsMissingDependencies (
            Job int NOT NULL,
            Script text NOT NULL,
            SimilarJob int NULL
        );

        _currentLocation := 'Find jobs that didn''t have cached dependencies';

        -- Find jobs that didn't have cached dependencies
        --
        INSERT INTO Tmp_JobsMissingDependencies( job, script )
        SELECT DISTINCT J.job, J.script
        FROM sw.t_jobs J
             INNER JOIN Tmp_JobsToCopy Src
               ON J.job = Src.job
             LEFT OUTER JOIN sw.t_job_step_dependencies JSD
               ON J.job = JSD.job
        WHERE JSD.job IS NULL;

        If FOUND Then
            _currentLocation := 'Inserting missing dependencies';

            -- One or more jobs did not have cached dependencies
            -- For each job, find a matching job that used the same script and _does_ have cached dependencies

            UPDATE Tmp_JobsMissingDependencies Target
            SET SimilarJob = Source.SimilarJob
            FROM ( SELECT Job,
                          SimilarJob,
                          Script
                   FROM ( SELECT MD.Job,
                                 JobsWithDependencies.Job AS SimilarJob,
                                 JobsWithDependencies.Script,
                                 Row_Number() OVER ( Partition By MD.Job
                                                     Order By JobsWithDependencies.Job ) AS SimilarJobRank
                          FROM Tmp_JobsMissingDependencies MD
                               INNER JOIN ( SELECT JH.job, JH.script
                                            FROM sw.t_jobs_history JH INNER JOIN
                                                 sw.t_job_step_dependencies_history JSD ON JH.job = JSD.job
                                          ) AS JobsWithDependencies
                                 ON MD.script = JobsWithDependencies.script AND
                                    JobsWithDependencies.job > MD.job
                       ) AS MatchQ
                   WHERE SimilarJobRank = 1
                 ) AS source
            WHERE Target.job = Source.job;

            INSERT INTO sw.t_job_step_dependencies( job,
                                                    step,
                                                    target_step,
                                                    condition_test,
                                                    test_value,
                                                    evaluated,
                                                    triggered,
                                                    enable_only )
            SELECT MD.job,
                   H.step,
                   H.target_step,
                   H.condition_test,
                   H.test_value,
                   0 AS Evaluated,
                   0 AS Triggered,
                   enable_only
            FROM sw.t_job_step_dependencies_history H
                 INNER JOIN Tmp_JobsMissingDependencies MD
                   ON H.job = MD.SimilarJob;

        End If;

        ---------------------------------------------------
        -- Jobs successfully copied
        ---------------------------------------------------

        _message := format('Copied %s %s from the history tables to the main tables', _jobsCopied, public.check_plural(_jobsCopied, 'job', 'jobs'));

        CALL public.post_log_entry ('Normal', _message, 'Copy_History_To_Job_Multi', 'sw');

        _currentLocation := 'Updating job parameters and storage server info';

        FOR _job IN
            SELECT Job
            FROM Tmp_JobsToCopy
            ORDER BY Job
        LOOP
            ---------------------------------------------------
            -- Update the job parameters in case any parameters have changed (in particular, storage path)
            ---------------------------------------------------

            _currentLocation := format('Call update_job_parameters for job ', _job);
            --
            CALL sw.update_job_parameters (
                        _job,
                        _infoOnly => false,
                        _settingsFileOverride => '',
                        _message => _message,
                        _returnCode => _returnCode);

            ---------------------------------------------------
            -- Make sure transfer_folder_path and storage_server are up-to-date in sw.t_jobs
            ---------------------------------------------------

            _currentLocation := format('Call validate_job_server_info for job ', _job);
            --
            CALL sw.validate_job_server_info (
                        _job,
                        _useJobParameters => true,
                        _message => _message,
                        _returnCode => _returnCode,
                        _debugMode => _debugMode);


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

            _jobsRefreshed := _jobsRefreshed + 1;

            If extract(epoch FROM (clock_timestamp() - _lastStatusTime)) >= 15 Then
                _lastStatusTime := clock_timestamp();
                _progressMsg := format('Updating job parameters and storage info for copied jobs: %s / %s', _jobsRefreshed, _jobsCopied);
                CALL public.post_log_entry ('Progress', _progressMsg, 'Copy_History_To_Job_Multi', 'sw');
            End If;

        END LOOP;

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

    END;

    DROP TABLE IF EXISTS Tmp_JobsToCopy;
    DROP TABLE IF EXISTS Tmp_JobsMissingDependencies;

END
$$;


ALTER PROCEDURE sw.copy_history_to_job_multi(IN _joblist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _debugmode boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE copy_history_to_job_multi(IN _joblist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _debugmode boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.copy_history_to_job_multi(IN _joblist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _debugmode boolean) IS 'CopyHistoryToJobMulti';

