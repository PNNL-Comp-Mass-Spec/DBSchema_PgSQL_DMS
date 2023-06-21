--
CREATE OR REPLACE PROCEDURE cap.update_task_context
(
    _bypassDMS boolean = false,
    _infoOnly boolean = false,
    _maxJobsToProcess int = 0,
    _logIntervalThreshold int = 15,
    _loggingEnabled boolean = false,
    _loopingUpdateInterval int = 5,
    _debugMode boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update context under which capture task job steps are assigned
**
**  Arguments:
**    _bypassDMS               If false, lookup the bypass mode in cap.t_process_step_control; otherwise, do not update states in tables in the public schema
**    _logIntervalThreshold    If this procedure runs longer than this threshold (in seconds), status messages will be posted to the log
**    _loggingEnabled          Set to true to immediately enable progress logging; if false, logging will auto-enable if _logIntervalThreshold seconds elapse
**    _loopingUpdateInterval   Seconds between detailed logging while looping sets of capture task jobs or steps to process
**
**  Auth:   grk
**  Date:   09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/08/2010 grk - Added call to make_new_archive_tasks_from_dms
**          05/25/2011 mem - Changed default value for _bypassDMS to false
**                         - Added call to retry_capture_for_dms_reset_tasks
**          02/23/2016 mem - Add Set XACT_ABORT on
**          06/13/2018 mem - No longer pass _debugMode to make_new_archive_tasks_from_dms
**          01/29/2021 mem - No longer pass _maxJobsToProcess to make_new_automatic_tasks
**          12/15/2023 mem - Ported to PostgreSQL
**          06/20/2023 mem - Use new step names in cap.t_process_step_control
**
*****************************************************/
DECLARE
    _statusMessage text;
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
    _message := '';
    _returnCode := '';

    -- Part A: Validate inputs, Remove deleted capture task jobs, Add new capture task jobs
    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

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

        -- Lookup the log level in cap.t_process_step_control

        SELECT enabled
        INTO _result
        FROM cap.t_process_step_control
        WHERE processing_step_name = 'LogLevel';

        -- Set _loggingEnabled if the LogLevel is 2 or higher
        If Coalesce(_result, 0) >= 2 Then
            _loggingEnabled := true;
        End If;

        -- See if DMS Updating is disabled in cap.t_process_step_control
        If Not _bypassDMS Then

            SELECT enabled
            INTO _result
            FROM cap.t_process_step_control
            WHERE processing_step_name = 'UpdateDMS';

            If FOUND And Coalesce(_result, 1) = 0 Then
                _bypassDMS := true;
            End If;
        End If;

        ---------------------------------------------------
        -- Call the various procedures for performing updates
        ---------------------------------------------------

        -- Make New Automatic Jobs
        --
        SELECT enabled
        INTO _result
        FROM cap.t_process_step_control
        WHERE processing_step_name = 'make_new_automatic_tasks';

        If FOUND And_result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
            _result := 1;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s make_new_automatic_tasks', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Task_Context', 'cap');
        End If;

        _currentLocation := 'Call make_new_automatic_tasks';

        If _result <> 0 And Not _bypassDMS Then
            call cap.make_new_automatic_tasks ();
        End If;

        -- Make New Jobs From Analysis Broker
        --
        SELECT enabled
        INTO _result
        FROM cap.t_process_step_control
        WHERE processing_step_name = 'make_new_tasks_from_analysis_broker';

        If FOUND And_result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
            _result := 1;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s make_new_tasks_from_analysis_broker', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Task_Context', 'cap');
        End If;

        _currentLocation := 'Call make_new_tasks_from_analysis_broker';

        If _result <> 0 Then
            CALL cap.make_new_tasks_from_analysis_broker (_infoOnly, _message => _message, _returnCode => _returnCode);
        End If;

        -- Make New Jobs From DMS
        --
        SELECT enabled
        INTO _result
        FROM cap.t_process_step_control
        WHERE processing_step_name = 'make_new_tasks_from_dms';

        If FOUND And_result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
            _result := 1;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s make_new_tasks_from_dms', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Task_Context', 'cap');
        End If;

        _currentLocation := 'Call make_new_tasks_from_dms';

        If _result <> 0 And Not _bypassDMS Then
            CALL cap.make_new_tasks_from_dms (
                                    _message => _message,
                                    _maxJobsToProcess => _maxJobsToProcess,
                                    _logIntervalThreshold => _logIntervalThreshold,
                                    _loggingEnabled => _loggingEnabled,
                                    _loopingUpdateInterval => _loopingUpdateInterval,
                                    _infoOnly => _infoOnly,
                                    _debugMode => _debugMode);

        End If;

        -- Make New Archive Jobs From DMS
        --
        SELECT enabled
        INTO _result
        FROM cap.t_process_step_control
        WHERE processing_step_name = 'make_new_archive_tasks_from_dms';

        If FOUND And_result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
            _result := 1;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s make_new_archive_tasks_from_dms', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Task_Context', 'cap');
        End If;

        _currentLocation := 'Call make_new_archive_tasks_from_dms';

        If _result <> 0 And Not _bypassDMS Then
            CALL cap.make_new_archive_tasks_from_dms (
                                    _message => _message,
                                    _maxJobsToProcess => _maxJobsToProcess,
                                    _logIntervalThreshold => _logIntervalThreshold,
                                    _loggingEnabled => _loggingEnabled,
                                    _loopingUpdateInterval => _loopingUpdateInterval,
                                    _infoOnly => _infoOnly);
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

    -- Part C: Create capture task job steps
    BEGIN

        SELECT enabled
        INTO _result
        FROM cap.t_process_step_control
        WHERE processing_step_name = 'create_task_steps';

        If FOUND And_result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
            _result := 1;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s create_task_steps', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Task_Context', 'cap');
        End If;

        _currentLocation := 'Call create_task_steps';

        If _result <> 0 Then
            CALL cap.create_task_steps (
                                    _message => _message,
                                    _maxJobsToProcess => _maxJobsToProcess,
                                    _logIntervalThreshold => _logIntervalThreshold,
                                    _loggingEnabled => _loggingEnabled,
                                    _loopingUpdateInterval => _loopingUpdateInterval,
                                    _infoOnly => _infoOnly,
                                    _returnCode => _returnCode,
                                    _debugMode => _debugMode)

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

    -- Part D: Update step states
    BEGIN

        SELECT enabled
        INTO _result
        FROM cap.t_process_step_control
        WHERE processing_step_name = 'update_task_step_states';

        If FOUND And_result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
            _result := 1;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s update_task_step_states', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Task_Context', 'cap');
        End If;

        _currentLocation := 'Call update_task_step_states';

        If _result <> 0 Then
            CALL cap.update_task_step_states (
                                    _message => _message,
                                    _infoOnly => _infoOnly,
                                    _maxJobsToProcess => _maxJobsToProcess,
                                    _loopingUpdateInterval => _loopingUpdateInterval);
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

    -- Part E: Update capture task job states
    --         This calls update_task_state, which calls update_dms_dataset_state, which calls update_dms_file_info_xml
    BEGIN

        SELECT enabled
        INTO _result
        FROM cap.t_process_step_control
        WHERE processing_step_name = 'update_task_state';

        If FOUND And_result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
            _result := 1;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s update_task_state', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Task_Context', 'cap');
        End If;

        _currentLocation := 'Call update_task_state';

        If _result <> 0 Then
            CALL cap.update_task_state (
                                    _bypassDMS => _bypassDMS,
                                    _message => _message,
                                    _maxJobsToProcess => _maxJobsToProcess,
                                    _loopingUpdateInterval => _loopingUpdateInterval,
                                    _infoOnly => _infoOnly);
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

    -- Part F: Retry capture for datasets that failed capture but for which the dataset state in DMS is 1=New
    BEGIN

        If Not _bypassDMS Then
            _result := 1;
            _action := 'Calling';
        Else
            _result := 0;
            _action := 'Skipping';
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s RetryCaptureForDMSResetJobs', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Task_Context', 'cap');
        End If;

        _currentLocation := 'Call retry_capture_for_dms_reset_tasks';

        If _result <> 0 Then
            CALL cap.retry_capture_for_dms_reset_tasks (_message => _message, _infoOnly => _infoOnly);
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

/*
    -- Part G: Update CPU Loading
    BEGIN

        SELECT enabled
        INTO _result
        FROM cap.t_process_step_control
        WHERE processing_step_name = 'UpdateCPULoading';

        If FOUND And_result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
            _result := 1;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s UpdateCPULoading', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Task_Context', 'cap');
        End If;

        _currentLocation := 'Call update_cpu_loading';

        If _result <> 0 Then
            CALL cap.update_cpu_loading _message => _message;
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

*/
    If _loggingEnabled Then
        _statusMessage := format('Update context complete: %s seconds elapsed', extract(epoch FROM CURRENT_TIMESTAMP - _startTime));
        CALL public.post_log_entry ('Normal', _statusMessage, 'Update_Task_Context', 'cap');
    End If;

END
$$;

COMMENT ON PROCEDURE cap.update_task_context IS 'UpdateTaskContext or UpdateContext';
