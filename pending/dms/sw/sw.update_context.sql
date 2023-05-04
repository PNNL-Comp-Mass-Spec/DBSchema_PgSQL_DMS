--
CREATE OR REPLACE PROCEDURE sw.update_context
(
    _bypassDMS boolean = false,
    _maxJobsToProcess int = 0,
    _logIntervalThreshold int = 15,
    _loggingEnabled boolean = false,
    _loopingUpdateInterval int = 5,
    _infoOnly boolean = false,
    _debugMode boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update context under which job steps are assigned
**
**  Arguments:
**    _bypassDMS               False: normal mode; will lookup the bypass mode in T_Process_Step_Control; true: test mode; state of DMS is not affected
**    _logIntervalThreshold    If this procedure runs longer than this threshold, status messages will be posted to the log
**    _loggingEnabled          Set to true to immediately enable progress logging; if false, logging will auto-enable if _logIntervalThreshold seconds elapse
**    _loopingUpdateInterval   Seconds between detailed logging while looping sets of jobs or steps to process
**    _infoOnly                True to preview changes that would be made
**    _debugMode               False for no debugging; true to see debug messages
**
**  Auth:   grk
**  Date:   05/30/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          01/09/2009 mem - Added parameter _infoOnly (http://prismtrac.pnl.gov/trac/ticket/713)
**          01/17/2009 mem - Now calling SyncJobInfo (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**          02/19/2009 grk - Added call to RemoveDMSDeletedJobs (Ticket #723)
**          06/02/2009 mem - Added parameter _maxJobsToProcess (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          06/03/2009 mem - Added parameters _logIntervalThreshold, _loggingEnabled, and _loopingUpdateInterval
**          06/04/2009 mem - Added Try/Catch error handling
**                         - Now using T_Process_Step_Control to determine whether or not to Update states in DMS
**          06/05/2009 mem - Added expanded support for T_Process_Step_Control
**          03/21/2011 mem - Added parameter _debugMode; now passing _infoOnly to AddNewJobs
**          01/12/2012 mem - Now passing _infoOnly to UpdateJobState
**          05/02/2015 mem - Now calling AutoFixFailedJobs
**          05/28/2015 mem - No longer calling ImportJobProcessors
**          11/20/2015 mem - Now calling UpdateActualCPULoading
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/30/2018 mem - Update comments
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _statusMessage text;
    _message text := '';
    _startTime timestamp := CURRENT_TIMESTAMP;
    _result int;
    _action text;
    _callingProcName text;
    _currentLocation text := 'Start';

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    -- Part A: Validate inputs, Remove Deleted Jobs, Add New Jobs, Hold/Resume/Reset jobs
    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------
        --
        _bypassDMS := Coalesce(_bypassDMS, false);
        _infoOnly := Coalesce(_infoOnly, false);
        _debugMode := Coalesce(_debugMode, false);
        _maxJobsToProcess := Coalesce(_maxJobsToProcess, 0);

        _loggingEnabled := Coalesce(_loggingEnabled, false);
        _logIntervalThreshold := Coalesce(_logIntervalThreshold, 15);
        _loopingUpdateInterval := Coalesce(_loopingUpdateInterval, 5);

        If _logIntervalThreshold = 0 Then
            _loggingEnabled := true;
        End If;

        -- Lookup the log level in sw.t_process_step_control

        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE processing_step_name = 'LogLevel';

        -- Set _loggingEnabled if the LogLevel is 2 or higher
        If Coalesce(_result, 0) >= 2 Then
            _loggingEnabled := true;
        End If;

        -- See if DMS Updating is disabled in sw.t_process_step_control
        If Not _bypassDMS Then

            SELECT enabled
            INTO _result
            FROM sw.t_process_step_control
            WHERE (processing_step_name = 'UpdateDMS');

            If Coalesce(_result, 1) = 0 Then
                _bypassDMS := true;
            End If;
        End If;

        ---------------------------------------------------
        -- Call the various procedures for performing updates
        ---------------------------------------------------
        --

        -- Step 1: Remove jobs deleted from DMS
        --
        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE (processing_step_name = 'RemoveDMSDeletedJobs');

        If _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
        End If;

        If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := _action || ' RemoveDMSDeletedJobs';
            Call public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call remove_dms_deleted_jobs';
        If _result > 0 Then
            Call sw.remove_dms_deleted_jobs _bypassDMS, _message => _message, _maxJobsToProcess => _maxJobsToProcess;
        End If;

        -- Step 2: Add new jobs, hold/resume/reset existing jobs
        --
        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE (processing_step_name = 'AddNewJobs');

        If _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
        End If;

        If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := _action || ' AddNewJobs';
            Call public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call add_new_jobs';
        If _result > 0 Then
            Call sw.add_new_jobs (
                _bypassDMS,
                _message => _message,
                _maxJobsToProcess => _maxJobsToProcess,
                _logIntervalThreshold => _LogIntervalThreshold,
                _loggingEnabled => _LoggingEnabled,
                _loopingUpdateInterval => _LoopingUpdateInterval,
                _infoOnly => _infoOnly,
                _debugMode => _DebugMode);

        End if;

    EXCEPTION
        -- Error caught; log the error, then continue at the next section
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation, _logError => Not _infoOnly);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

    COMMIT;

    -- Part B: Import Processors and Sync Job Info
    BEGIN

        -- Step 3: Import Processors
        --
        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE (processing_step_name = 'ImportProcessors');

        If _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
        End If;

        If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := _action || ' ImportProcessors';
            Call public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call import_processors';
        If _result > 0 Then
            Call sw.import_processors (_bypassDMS, _message => _message);
        End If;

        /*
        ---------------------------------------------------
        -- Deprecated in May 2015:
        -- Import Job Processors
        --
        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE (processing_step_name = 'ImportJobProcessors');

        If _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
        End If;

        If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := _action || ' ImportJobProcessors';
            Call public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call import_job_processors';
        If _result > 0 Then
            Call sw.import_job_processors _bypassDMS, _message => _message;
        End If;
        */

        -- Step 4: Sync Job Info
        --
        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE (processing_step_name = 'SyncJobInfo');

        If _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
        End If;

        If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := _action || ' SyncJobInfo';
            Call public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call sync_job_info';
        If _result > 0 Then
            Call sw.sync_job_info _bypassDMS, _message => _message;
        End If;

    EXCEPTION
        -- Error caught; log the error, then continue at the next section
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation, _logError => Not _infoOnly);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

    COMMIT;

    -- Part C
    BEGIN

        -- Step 5: Create job steps
        --
        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE (processing_step_name = 'CreateJobSteps');

        If _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
        End If;

        If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := _action || ' CreateJobSteps';
            Call public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call create_job_steps';
        If _result > 0 Then
            Call sw.create_job_steps (
                    _message => _message,
                    _returnCode => _returnCode,
                    _maxJobsToProcess => _maxJobsToProcess,
                    _logIntervalThreshold => _LogIntervalThreshold,
                    _loggingEnabled => _LoggingEnabled,
                    _loopingUpdateInterval => _LoopingUpdateInterval,
                    _infoOnly => _infoOnly,
                    _debugMode => _debugMode
                    );

    EXCEPTION
        -- Error caught; log the error, then continue at the next section
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation, _logError => Not _infoOnly);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

    COMMIT;

    -- Part D
    BEGIN

        -- Step 6: Update step states
        --
        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE (processing_step_name = 'UpdateStepStates');

        If _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
        End If;

        If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := _action || ' UpdateStepStates';
            Call public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call update_step_states';
        If _result > 0 Then
            Call sw.update_step_states (
                  _message => _message,
                  _infoOnly => _infoOnly,
                  _maxJobsToProcess => _maxJobsToProcess,
                  _loopingUpdateInterval => _LoopingUpdateInterval);
        End If;

    EXCEPTION
        -- Error caught; log the error, then continue at the next section
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation, _logError => Not _infoOnly);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

    COMMIT;

    -- Part E
    BEGIN

        -- Step 7: Update job states
        --
        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE (processing_step_name = 'UpdateJobState');

        If _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
        End If;

        If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := _action || ' UpdateJobState';
            Call public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call update_job_state';
        If _result > 0 Then
            Call sw.update_job_state (
                        _bypassDMS,
                        _message => _message,
                        _maxJobsToProcess => _maxJobsToProcess,
                        _loopingUpdateInterval => _loopingUpdateInterval,
                        _infoOnly => _infoOnly);

    EXCEPTION
        -- Error caught; log the error, then continue at the next section
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation, _logError => Not _infoOnly);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

    COMMIT;

    -- Part F
    BEGIN

        -- Step 8: Update CPU loading and memory usage
        --
        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE (processing_step_name = 'UpdateCPULoading');

        If _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
        End If;

        If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := _action || ' UpdateCPULoading';
            Call public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call update_cpu_loading';
        If _result > 0 Then
            -- First update actual_cpu_load in sw.t_job_steps
            Call sw.update_actual_cpu_loading (_infoOnly => false);

            -- Now update cpus_available in sw.t_machines
            Call sw.update_cpu_loading (_message => _message);
        End If;

    EXCEPTION
        -- Error caught; log the error, then continue at the next section
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation, _logError => Not _infoOnly);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

    COMMIT;

    -- Part G
    BEGIN

        -- Step 9: Auto fix failed jobs
        --
        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE (processing_step_name = 'AutoFixFailedJobs');

        If _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
        End If;

        If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := _action || ' AutoFixFailedJobs';
            Call public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call auto_fix_failed_jobs';
        If _result > 0 Then
            Call sw.auto_fix_failed_jobs (_message => _message => _message, _infoOnly => _infoOnly);
        End If;

    EXCEPTION
        -- Error caught; log the error, then continue at the next section
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation, _logError => Not _infoOnly);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

    COMMIT;

    If _loggingEnabled Then
        _statusMessage := format('UpdateContext complete: %s seconds elapsed',
                                 extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold;

        Call public.post_log_entry ('Normal', _statusMessage, 'Update_Context', 'sw');
    End If;

END
$$;

COMMENT ON PROCEDURE sw.update_context IS 'UpdateContext';
