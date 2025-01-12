--
-- Name: set_step_task_complete(integer, integer, integer, text, integer, text, text, text, text, real, timestamp without time zone, timestamp without time zone, text, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.set_step_task_complete(IN _job integer, IN _step integer, IN _completioncode integer, IN _completionmessage text DEFAULT ''::text, IN _evaluationcode integer DEFAULT 0, IN _evaluationmessage text DEFAULT ''::text, IN _organismdbname text DEFAULT ''::text, IN _remoteinfo text DEFAULT ''::text, IN _remotetimestamp text DEFAULT NULL::text, IN _remoteprogress real DEFAULT NULL::real, IN _remotestart timestamp without time zone DEFAULT NULL::timestamp without time zone, IN _remotefinish timestamp without time zone DEFAULT NULL::timestamp without time zone, IN _processorname text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Mark job step as complete
**      Also update CPU and memory info tracked by t_machines
**
**  Arguments:
**    _job                  Analysis job number
**    _step                 Step number
**    _completionCode       Completion code
**    _completionMessage    Completion message
**    _evaluationCode       Evaluation code
**    _evaluationMessage    Evaluation message
**    _organismDBName       Organism DB name (FASTA file name)
**    _remoteInfo           Remote server info for jobs with _completionCode = 25
**    _remoteTimestamp      Timestamp for the .info file for remotely running jobs (e.g. '20170515_1532' in file Job1449504_Step03_20170515_1532.info)
**    _remoteProgress       Percent complete for jobs running remotely
**    _remoteStart          Time the remote processor actually started processing the job
**    _remoteFinish         Time the remote processor actually finished processing the job
**    _processorName        Name of the processor setting the job as complete
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   grk
**  Date:   05/07/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          06/17/2008 dac - Added default values for completionMessage, evaluationCode, and evaluationMessage
**          10/05/2009 mem - Now allowing for CPU_Load to be null in T_Job_Steps
**          10/17/2011 mem - Added column Memory_Usage_MB
**          09/25/2012 mem - Expanded _organismDBName to varchar(128)
**          09/09/2014 mem - Added support for completion code 16 (CLOSEOUT_FILE_NOT_IN_CACHE)
**          09/12/2014 mem - Added PBF_Gen as a valid tool for completion code 16
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**                         - Now looking up machine using T_Local_Processors
**          10/30/2014 mem - Added support for completion code 17 (CLOSEOUT_UNABLE_TO_USE_MZ_REFINERY)
**          03/11/2015 mem - Now updating Completion_Message when completion code 16 or 17 is encountered more than once in a 24 hour period
**          04/17/2015 mem - Now using Uses_All_Cores for determining the number of cores to add back to CPUs_Available
**          11/18/2015 mem - Add Actual_CPU_Load
**          12/31/2015 mem - Added support for completion code 20 (CLOSEOUT_NO_DATA)
**          01/05/2016 mem - Tweak warning message for DeconTools results without data
**          06/17/2016 mem - Add missing space in log message
**          06/20/2016 mem - Include the completion code description in logged messages
**          12/02/2016 mem - Lookup step tools with shared results in T_Step_Tools when initializing _sharedResultStep
**          05/11/2017 mem - Add support for _completionCode 25 (RUNNING_REMOTE) and columns Next_Try and Retry_Count
**          05/12/2017 mem - Add parameter _remoteInfo, update Remote_Info_ID in T_Job_Steps, and update T_Remote_Info
**          05/15/2017 mem - Add parameter _remoteTimestamp, which is used to define the remote info file in the TaskQueuePath folder
**          05/18/2017 mem - Use GetRemoteInfoID to resolve _remoteInfo to _remoteInfoID
**          05/23/2017 mem - Add parameter _remoteProgress
**                           Update Remote_Finish if a remotely running job has finished (success or failure)
**          05/26/2017 mem - Add completion code 26 (FAILED_REMOTE), which leads to step state 16
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/12/2017 mem - Skip waiting step tools MSGF, IDPicker, and MSAlign_Quant when a DataExtractor step reports NO_DATA
**          10/17/2017 mem - Fix the warning logged when the DataExtractor reports no data
**          10/31/2017 mem - Add parameter _processorName
**          03/14/2018 mem - Use a shorter interval when updating Next_Try for remotely running jobs
**          03/29/2018 mem - Decrease _adjustedHoldoffInterval from 90 to 30 minutes
**          04/19/2018 mem - Add parameters _remoteStart and _remoteFinish
**          04/25/2018 mem - Stop setting Remote_Finish to the current date since _remoteFinish provides that info
**          06/12/2018 mem - Send _maxLength to Append_To_Text
**          10/18/2018 mem - Add output parameter _message
**          01/31/2020 mem - Add _returnCode, which duplicates the integer returned by this procedure; _returnCode is varchar for compatibility with Postgres error codes
**          12/14/2020 mem - Add support for completion code 18 (CLOSEOUT_SKIPPED_MZ_REFINERY)
**          03/12/2021 mem - Add support for completion codes 21 (CLOSEOUT_SKIPPED_MSXML_GEN) and 22 (CLOSEOUT_SKIPPED_MAXQUANT)
**                         - Expand _completionMessage and _evaluationMessage to varchar(512)
**          09/21/2021 mem - Add support for completion code 23 (CLOSEOUT_RESET_JOB_STEP)
**          08/26/2022 mem - Use new column name in T_Log_Entries
**          03/29/2023 mem - Add support for completion codes 27 and 28 (SKIPPED_DIA_NN_SPEC_LIB and WAITING_FOR_DIA_NN_SPEC_LIB)
**          08/11/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Use default delimiter and max length when calling append_to_text()
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          02/08/2024 mem - If _completionCode is 20 and the step tool is DiaNN, set the job step as complete, but skip the subsequent data extraction step
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**          08/14/2024 mem - Set _logErrorsToPublicLogTable to false when calling post_log_entry with warning messages
**          01/09/2025 mem - Add support for completion code 24 (CLOSEOUT_RESET_JOB_STEP_INSUFFICIENT_MEMORY)
**                         - Add/update table t_job_step_reset_stats when the completion code is 23 or 24
**          01/10/2025 mem - Log an error message when a job step has been reset over 35 times
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _stepToolsToSkip text[];
    _jobStepDescription text;
    _jobStepDescriptionCapital text;
    _jobInfo record;
    _stepState int;
    _resetSharedResultStep boolean := false;
    _handleSkippedStep boolean := false;
    _completionCodeDescription text := 'Unknown completion reason';
    _diskSpaceResetCount int;
    _memoryResetCount int;
    _nextTry timestamp := CURRENT_TIMESTAMP;
    _holdoffIntervalMinutes int;
    _adjustedHoldoffInterval int;
    _remoteInfoID int := 0;
    _sharedResultStep int := -1;
    _newTargetStep int := -1;
    _nextStep int := -1;
    _abortReset boolean;
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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _job           := Coalesce(_job, 0);
    _step          := Coalesce(_step, 0);
    _processorName := Trim(Coalesce(_processorName, ''));

    _jobStepDescription        := format('job %s, step %s', _job, _step);
    _jobStepDescriptionCapital := format('Job %s, step %s', _job, _step);

    ---------------------------------------------------
    -- Get current state of this job step
    ---------------------------------------------------

    SELECT LP.Machine,
           CASE WHEN ST.Uses_All_Cores > 0 AND JS.Actual_CPU_Load = JS.CPU_Load
                THEN Coalesce(M.Total_CPUs, 1)
                ELSE Coalesce(JS.Actual_CPU_Load, 1)
           END AS CpuLoad,
           Coalesce(JS.memory_usage_mb, 0) AS MemoryUsageMB,
           JS.State,
           JS.processor AS JobStepsProcessor,
           JS.tool AS StepTool,
           JS.retry_count AS RetryCount,
           J.Dataset_ID AS DatasetID
    INTO _jobInfo
    FROM sw.t_job_steps JS
         INNER JOIN sw.t_local_processors LP
           ON LP.processor_name = JS.processor
         INNER JOIN sw.t_step_tools ST
           ON ST.step_tool = JS.tool
         LEFT OUTER JOIN sw.t_jobs J            -- The job should exist in t_jobs, but using a left join in case it doesn't
           ON J.job = JS.job
         LEFT OUTER JOIN sw.t_machines M
           ON LP.machine = M.machine
    WHERE JS.job = _job AND
          JS.step = _step;

    If Not FOUND Then
        _message := format('Empty query results for job %s, step %s when obtaining the current state of the job step using sw.t_job_steps', _job, _step);

        CALL public.post_log_entry ('Error', _message, 'Set_Step_Task_Complete', 'sw');

        _returnCode := 'U5265';
        RETURN;
    End If;

    If Coalesce(_jobInfo.Machine, '') = '' Then
        _message := format('Could not find machine name in sw.t_local_processors using sw.t_job_steps; cannot mark %s complete for processor %s',
                            _jobStepDescription, _processorName);

        CALL public.post_log_entry ('Error', _message, 'Set_Step_Task_Complete', 'sw');

        _returnCode := 'U5266';
        RETURN;
    End If;

    If _jobInfo.State <> 4 Then
        _message := format('%s is not in the correct state (4) to be marked complete by processor %s; actual state is %s',
                            _jobStepDescriptionCapital, _processorName, _jobInfo.State);

        CALL public.post_log_entry ('Error', _message, 'Set_Step_Task_Complete', 'sw');

        _returnCode := 'U5267';
        RETURN;
    Else
        If _processorName <> '' And _jobInfo.JobStepsProcessor <> _processorName::citext Then

            _message := format('%s is being processed by %s; processor %s is not allowed to mark it as complete',
                                _jobStepDescriptionCapital, _jobInfo.JobStepsProcessor, _processorName);

            CALL public.post_log_entry ('Error', _message, 'Set_Step_Task_Complete', 'sw');

            _returnCode := 'U5268';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Determine completion state
    ---------------------------------------------------

    If _completionCode = 0 Then
        _stepState := 5; -- success
        _completionCodeDescription := 'Success';
    Else
        _stepState := 0;

        If _completionCode = 16 Then        -- CLOSEOUT_FILE_NOT_IN_CACHE
            _stepState := 1; -- waiting
            _resetSharedResultStep := true;
            _completionCodeDescription := 'File not in cache';
        End If;

        If _completionCode = 17 Then        -- CLOSEOUT_UNABLE_TO_USE_MZ_REFINERY
            _stepState := 3; -- skipped
            _handleSkippedStep := true;
            _completionCodeDescription := 'Unable to use MZ_Refinery';
        End If;

        If _completionCode = 18 Then        -- CLOSEOUT_SKIPPED_MZ_REFINERY
            _stepState := 3; -- skipped
            _handleSkippedStep := true;
            _completionCodeDescription := 'Skipped MZ_Refinery';
        End If;

        If _completionCode = 21 Then        -- CLOSEOUT_SKIPPED_MSXML_GEN
            _stepState := 3; -- skipped
            _handleSkippedStep := true;
            _completionCodeDescription := 'Skipped MSXml_Gen';
        End If;

        If _completionCode = 22 Then        -- CLOSEOUT_SKIPPED_MAXQUANT
            _stepState := 3; -- skipped
            _handleSkippedStep := true;
            _completionCodeDescription := 'Skipped MaxQuant';
        End If;

        If _completionCode = 23 Or          -- CLOSEOUT_RESET_JOB_STEP
           _completionCode = 24             -- CLOSEOUT_RESET_JOB_STEP_INSUFFICIENT_MEMORY
        Then
            -- Add/update table t_job_step_reset_stats

            SELECT disk_space_count, memory_count
            INTO _diskSpaceResetCount, _memoryResetCount
            FROM sw.t_job_step_reset_stats
            WHERE job = _job AND step = _step;

            If _completionCode = 23 Then
                _diskSpaceResetCount := Coalesce(_diskSpaceResetCount, 0) + 1;
            Else
                _memoryResetCount := Coalesce(_memoryResetCount, 0) + 1;
            End If;

            If FOUND Then
                UPDATE sw.t_job_step_reset_stats
                SET disk_space_count = Coalesce(_diskSpaceResetCount, 0),
                    memory_count     = Coalesce(_memoryResetCount, 0),
                    last_affected = CURRENT_TIMESTAMP
                WHERE job = _job AND step = _step;
            Else
                INSERT INTO sw.t_job_step_reset_stats (job, step, tool, disk_space_count, memory_count, dataset_id)
                VALUES (_job, _step, _jobInfo.StepTool, Coalesce(_diskSpaceResetCount, 0), Coalesce(_memoryResetCount, 0), _jobInfo.DatasetID);
            End If;

            -- If a job step is reset more than 35 times, set _stepState to 6 (Failed)

            If _completionCode = 23 And Coalesce(_diskSpaceResetCount, 0) > 35 Then
                _stepState := 6;    -- Failed
                _completionCodeDescription := 'Job step reset over 35 times due to insufficient free disk space';
            ElsIf _completionCode = 24 And Coalesce(_memoryResetCount, 0) > 35 Then
                _stepState := 6;    -- Failed
                _completionCodeDescription := 'Job step reset over 35 times due to insufficient available memory';
            Else
                _stepState := 2;    -- New
                _handleSkippedStep := false;

                If _completionCode = 23 Then
                    _completionCodeDescription := 'Insufficient disk space; retry';
                Else
                    _completionCodeDescription := 'Insufficient memory; retry';
                End If;
            End If;

            If _stepState = 6 Then
                UPDATE sw.t_job_step_reset_stats
                SET comment = _completionCodeDescription
                WHERE job = _job AND step = _step;

                _message := Replace(_completionCodeDescription, 'Job step', format('Job %s, step %s has been', _job, _step));
                CALL post_log_entry ('Error', _message, 'Set_Step_Task_Complete', 'sw', _logErrorsToPublicLogTable => false);
            End If;
        End If;

        If _completionCode = 20 Then        -- CLOSEOUT_NO_DATA
            _completionCodeDescription := 'No Data';

            -- Note that Formularity and NOMSI jobs that report completion code 20 are handled in AutoFixFailedJobs

            If _jobInfo.StepTool = 'Decon2LS_V2' Then
                -- Treat 'No_data' results for DeconTools as a completed job step but skip the next step if it is LCMSFeatureFinder
                _stepState := 5;    -- Complete

                -- Append to the array that tracks step tools that should be skipped when a job step reports NO_DATA
                _stepToolsToSkip := array_append(_stepToolsToSkip, 'LCMSFeatureFinder');

                _message := format('Warning, %s has no results in the DeconTools _isos.csv file; either it is a bad dataset or analysis parameters are incorrect', _jobStepDescription);
                CALL public.post_log_entry ('Error', _message, 'Set_Step_Task_Complete', 'sw', _logErrorsToPublicLogTable => false);
            End If;

            If _jobInfo.StepTool = 'DataExtractor' Then
                -- Treat 'No_data' results for the DataExtractor as a completed job step but skip later job steps that match certain tools
                _stepState := 5;    -- Complete

                -- Append to the array that tracks step tools that should be skipped when a job step reports NO_DATA
                _stepToolsToSkip := array_cat(_stepToolsToSkip, ARRAY ['MSGF', 'IDPicker', 'MSAlign_Quant']);

                _message := format('Warning, %s has an empty synopsis file (no results above threshold); either it is a bad dataset or analysis parameters are incorrect', _jobStepDescription);
                CALL public.post_log_entry ('Error', _message, 'Set_Step_Task_Complete', 'sw', _logErrorsToPublicLogTable => false);
            End If;

            If _jobInfo.StepTool = 'DiaNN' Then
                -- Treat "No_data" results for DiaNN as a completed job step but skip the DataExtractor job step
                _stepState := 5;    -- Complete

                -- Append to the array that tracks step tools that should be skipped when a job step reports NO_DATA
                _stepToolsToSkip := array_append(_stepToolsToSkip, 'DataExtractor');

                _message := format('Warning, %s has an empty report.tsv file (no results above threshold); either it is a bad dataset or analysis parameters are incorrect', _jobStepDescription);
                CALL post_log_entry ('Error', _message, 'Set_Step_Task_Complete', 'sw', _logErrorsToPublicLogTable => false);
            End If;

        End If;

        If _completionCode = 25 Or  -- RUNNING_REMOTE
           _completionCode = 28     -- WAITING_FOR_DIA_NN_SPEC_LIB
        Then

            If _completionCode = 25 Then
                _stepState := 9;    -- Running_Remote
                _completionCodeDescription := 'Running remote';

            ElsIf _completionCode = 28 Then
                _stepState := 11;   -- Waiting_for_File
                _completionCodeDescription := 'Waiting for DIA-NN spectral library to be generated by another job';

            Else
                _stepState := 6;    -- Failed
                _completionCodeDescription := format('Unrecognized completion code; expecting 25 or 28 but actually %s', _completionCode);
            End If;

            SELECT holdoff_interval_minutes
            INTO _holdoffIntervalMinutes
            FROM sw.t_step_tools
            WHERE step_tool = _jobInfo.StepTool;

            If Coalesce(_holdoffIntervalMinutes, 0) < 1 Then
                _holdoffIntervalMinutes := 3;
            End If;

            _jobInfo.RetryCount := _jobInfo.RetryCount + 1;

            If _jobInfo.RetryCount < 1 Then
                _jobInfo.RetryCount := 1;
            End If;

            -- Wait longer after each check of remote status, with a maximum holdoff interval of 30 minutes
            -- If _holdoffIntervalMinutes is 5, will wait 5 minutes initially, then wait 6 minutes after the next check, 7, etc.

            _adjustedHoldoffInterval := _holdoffIntervalMinutes + (_jobInfo.RetryCount - 1);

            If _adjustedHoldoffInterval > 30 Then
                _adjustedHoldoffInterval := 30;
            End If;

            If _remoteProgress > 0 Then
                -- Bump _adjustedHoldoffInterval down based on _remoteProgress; examples:
                -- If _adjustedHoldoffInterval is 20 and _remoteProgress is 10, change _adjustedHoldoffInterval to 19
                -- If _adjustedHoldoffInterval is 20 and _remoteProgress is 50, change _adjustedHoldoffInterval to 15
                -- If _adjustedHoldoffInterval is 20 and _remoteProgress is 90, change _adjustedHoldoffInterval to 11
                _adjustedHoldoffInterval := _adjustedHoldoffInterval - _adjustedHoldoffInterval * _remoteProgress / 200;
            End If;

            _nextTry := CURRENT_TIMESTAMP + make_interval(mins => _adjustedHoldoffInterval);
        End If;

        If _completionCode = 26 Then    -- FAILED_REMOTE
            _stepState := 16;   -- Failed_Remote
            _completionCodeDescription := 'Failed remote';
        End If;

        If _completionCode = 27 Then    -- SKIPPED_DIA_NN_SPEC_LIB
            _stepState := 3;    -- Skipped
            _handleSkippedStep := true;
            _completionCodeDescription := 'Skipped DIA-NN spectral library creation';
        End If;

        If _stepState = 0 Then
            _stepState := 6;    -- Failed
            _completionCodeDescription := 'General error';
        End If;
    End If;

    ---------------------------------------------------
    -- Update job step
    ---------------------------------------------------

    UPDATE sw.t_job_steps
    SET    state = _stepState,
           finish = CURRENT_TIMESTAMP,
           completion_code = _completionCode,
           completion_message = _completionMessage,
           evaluation_code = _evaluationCode,
           evaluation_message = _evaluationMessage,
           next_try = _nextTry,
           retry_count = _jobInfo.RetryCount,
           remote_timestamp = _remoteTimestamp,
           remote_progress = _remoteProgress,
           remote_start = _remoteStart,
           remote_finish = _remoteFinish
    WHERE job = _job AND
          step = _step;

    ---------------------------------------------------
    -- Update machine loading for this job step's processor's machine
    ---------------------------------------------------

    UPDATE sw.t_machines
    SET cpus_available = cpus_available + _jobInfo.CpuLoad,
        memory_available = memory_available + _jobInfo.MemoryUsageMB
    WHERE machine = _jobInfo.Machine;

    ---------------------------------------------------
    -- Update sw.t_remote_info if appropriate
    ---------------------------------------------------

    If Coalesce(_remoteInfo, '') <> '' Then

        _remoteInfoID := sw.get_remote_info_id(_remoteInfo, _infoOnly => false);

        If Coalesce(_remoteInfoID, 0) = 0 Then
            ---------------------------------------------------
            -- Something went wrong; _remoteInfo wasn't found in sw.t_remote_info
            -- and get_remote_info_id() was unable to add it with the Merge statement
            ---------------------------------------------------

            UPDATE sw.t_job_steps
            SET remote_info_id = 1
            WHERE job = _job AND
                  step = _step AND
                  remote_info_id IS NULL;
        Else

            UPDATE sw.t_job_steps
            SET remote_info_id = _remoteInfoID,
                remote_progress = CASE WHEN _stepState = 5 THEN 100 ELSE remote_progress END
            WHERE job = _job AND
                  step = _step;

            UPDATE sw.t_remote_info
            SET most_recent_job = _job,
                last_used = CURRENT_TIMESTAMP
            WHERE remote_info_id = _remoteInfoID;

        End If;

    End If;

    _abortReset := false;

    If _resetSharedResultStep Then
        -- Possibly reset the the DTA_Gen, DTA_Refinery, Mz_Refinery,
        -- MSXML_Gen, MSXML_Bruker, PBF_Gen, or ProMex step just upstream from this step

        SELECT step
        INTO _sharedResultStep
        FROM sw.t_job_steps
        WHERE job = _job AND
              step < _step AND
              tool IN (SELECT Step_Tool FROM sw.t_step_tools WHERE shared_result_version > 0)
        ORDER BY step DESC
        LIMIT 1;

        If Not Found Then
            _message := format('Job %s does not have a Mz_Refinery, MSXML_Gen, MSXML_Bruker, PBF_Gen, or ProMex step prior to step %s; Completion code %s (%s) is invalid',
                               _job, _step, _completionCode, _completionCodeDescription);

            CALL public.post_log_entry ('Error', _message, 'Set_Step_Task_Complete', 'sw');

            _abortReset := true;
        Else

            _message := format('Re-running step %s for job %s because step %s reported completion code %s (%s)',
                               _sharedResultStep, _job, _step, _completionCode, _completionCodeDescription);

            If Exists (SELECT entry_id
                       FROM sw.t_log_entries
                       WHERE Message = _message AND
                             type = 'Normal' AND
                             Entered >= CURRENT_TIMESTAMP - INTERVAL '1 day'
                      ) Then

                _message := format('has already reported completion code %s (%s) within the last 24 hours',
                                   _completionCode, _completionCodeDescription);

                UPDATE sw.t_job_steps
                SET state = 7,        -- Holding
                    completion_message = public.append_to_text(completion_message, _message)
                WHERE job = _job AND
                      step = _step;

                _message := format('Step %s in job %s %s; will not reset step %s again because this likely represents a problem; this step is now in state "holding"',
                                   _step, _job, _message, _sharedResultStep);

                CALL public.post_log_entry ('Error', _message, 'Set_Step_Task_Complete', 'sw');

                _abortReset := true;

            End If;

            If Not _abortReset Then
                CALL public.post_log_entry ('Normal', _message, 'Set_Step_Task_Complete', 'sw');

                -- Reset shared results step just upstream from this step

                UPDATE sw.t_job_steps
                SET state = 2,                  -- 2=Enabled
                    tool_version_id = 1,        -- 1=Unknown
                    next_try = CURRENT_TIMESTAMP,
                    remote_info_id = 1          -- 1=Unknown
                WHERE job = _job AND
                      step = _sharedResultStep AND
                      NOT state IN (4, 9);      -- Do not reset the step if it is already running

                UPDATE sw.t_job_step_dependencies
                SET evaluated = 0,
                    triggered = 0
                WHERE job = _job AND
                      step = _step;

                UPDATE sw.t_job_step_dependencies
                SET evaluated = 0,
                    triggered = 0
                WHERE job = _job AND
                      target_step = _sharedResultStep;

            End If;
        End If;

    End If;

    If _handleSkippedStep And Not _abortReset Then
        -- This step was skipped
        -- Update sw.t_job_step_dependencies

        SELECT target_step
        INTO _newTargetStep
        FROM sw.t_job_step_dependencies
        WHERE job = _job AND
              step = _step;

        SELECT step
        INTO _nextStep
        FROM sw.t_job_step_dependencies
        WHERE job = _job AND
              target_step = _step AND
              Coalesce(condition_test, '') <> 'Target_Skipped';

        If _newTargetStep > -1 And _newTargetStep > -1 Then

            UPDATE sw.t_job_step_dependencies
            SET target_step = _newTargetStep
            WHERE job = _job AND step = _nextStep;

            _message := format('Updated job step dependencies for job %s since step %s has been skipped', _job, _step);
            CALL public.post_log_entry ('Normal', _message, 'Set_Step_Task_Complete', 'sw');
        End If;

    End If;

    If Not _abortReset And array_length(_stepToolsToSkip, 1) > 0 Then

        -- Skip specific waiting step tools for this job

        UPDATE sw.t_job_steps JS
        SET state = 3
        FROM (SELECT unnest(_stepToolsToSkip) AS tool) ToolsToSkip
        WHERE JS.tool = ToolsToSkip.tool AND
              JS.Job = _job AND
              JS.State = 1;

    End If;

    ---------------------------------------------------
    -- Update FASTA file name (if one was passed in from the Analysis Manager)
    ---------------------------------------------------

    If Coalesce(_organismDBName,'') <> '' Then
        UPDATE sw.t_jobs
        SET organism_db_name = _organismDBName
        WHERE job = _job;
    End If;

END
$$;


ALTER PROCEDURE sw.set_step_task_complete(IN _job integer, IN _step integer, IN _completioncode integer, IN _completionmessage text, IN _evaluationcode integer, IN _evaluationmessage text, IN _organismdbname text, IN _remoteinfo text, IN _remotetimestamp text, IN _remoteprogress real, IN _remotestart timestamp without time zone, IN _remotefinish timestamp without time zone, IN _processorname text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_step_task_complete(IN _job integer, IN _step integer, IN _completioncode integer, IN _completionmessage text, IN _evaluationcode integer, IN _evaluationmessage text, IN _organismdbname text, IN _remoteinfo text, IN _remotetimestamp text, IN _remoteprogress real, IN _remotestart timestamp without time zone, IN _remotefinish timestamp without time zone, IN _processorname text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.set_step_task_complete(IN _job integer, IN _step integer, IN _completioncode integer, IN _completionmessage text, IN _evaluationcode integer, IN _evaluationmessage text, IN _organismdbname text, IN _remoteinfo text, IN _remotetimestamp text, IN _remoteprogress real, IN _remotestart timestamp without time zone, IN _remotefinish timestamp without time zone, IN _processorname text, INOUT _message text, INOUT _returncode text) IS 'SetStepTaskComplete';

