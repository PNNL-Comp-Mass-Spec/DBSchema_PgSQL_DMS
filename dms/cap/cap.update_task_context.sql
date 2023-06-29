--
-- Name: update_task_context(boolean, integer, integer, boolean, integer, boolean, boolean, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.update_task_context(IN _bypassdms boolean DEFAULT false, IN _maxjobstoprocess integer DEFAULT 0, IN _logintervalthreshold integer DEFAULT 15, IN _loggingenabled boolean DEFAULT false, IN _loopingupdateinterval integer DEFAULT 5, IN _infoonly boolean DEFAULT false, IN _debugmode boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update context under which capture task job steps are assigned
**
**  Arguments:
**    _bypassDMS               If false, lookup the bypass mode in cap.t_process_step_control; otherwise, do not update states in tables in the public schema
**    _maxJobsToProcess        Maximum number of jobs to process
**    _logIntervalThreshold    If this procedure runs longer than this threshold (in seconds), status messages will be posted to the log
**    _loggingEnabled          Set to true to immediately enable progress logging; if false, logging will auto-enable if _logIntervalThreshold seconds elapse
**    _loopingUpdateInterval   Seconds between detailed logging while looping sets of capture task jobs or steps to process
**    _infoOnly                True to preview changes that would be made
**    _debugMode               When true, show additional information when calling cap.create_task_steps (which calls cap.create_steps_for_task, cap.finish_task_creation, and cap.move_tasks_to_main_tables)
**                             Additionally, cap.move_tasks_to_main_tables stores the contents of the temporary tables in the following tables when _infoOnly is false and _debugMode is true
**                               cap.T_Tmp_New_Jobs
**                               cap.T_Tmp_New_Job_Steps
**                               cap.T_Tmp_New_Job_Step_Dependencies
**                               cap.T_Tmp_New_Job_Parameters
**
**  Auth:   grk
**  Date:   09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/08/2010 grk - Added call to make_new_archive_tasks_from_dms
**          05/25/2011 mem - Changed default value for _bypassDMS to false
**                         - Added call to retry_capture_for_dms_reset_tasks
**          02/23/2016 mem - Add Set XACT_ABORT on
**          06/13/2018 mem - No longer pass _debugMode to make_new_archive_tasks_from_dms
**          01/29/2021 mem - No longer pass _maxJobsToProcess to make_new_automatic_tasks
**          06/20/2023 mem - Use new step names in cap.t_process_step_control
**          06/21/2023 mem - Ported to PostgreSQL
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

    -- Part A: Validate inputs, remove deleted capture task jobs, add new capture task jobs
    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _bypassDMS := Coalesce(_bypassDMS, false);
        _maxJobsToProcess := Coalesce(_maxJobsToProcess, 0);

        _logIntervalThreshold := Coalesce(_logIntervalThreshold, 15);
        _loggingEnabled := Coalesce(_loggingEnabled, false);
        _loopingUpdateInterval := Coalesce(_loopingUpdateInterval, 5);

        _infoOnly := Coalesce(_infoOnly, false);
        _debugMode := Coalesce(_debugMode, false);

        If _logIntervalThreshold = 0 Then
            _loggingEnabled := true;
        End If;

        -- Lookup the log level in cap.t_process_step_control

        SELECT enabled
        INTO _result
        FROM cap.t_process_step_control
        WHERE processing_step_name = 'LogLevel';

        -- Set _loggingEnabled if the LogLevel is 2 or higher
        If FOUND And Coalesce(_result, 0) >= 2 Then
            _loggingEnabled := true;
        End If;

        If Not _bypassDMS Then

            -- See if DMS Updating is disabled in cap.t_process_step_control

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
        -- If an option is missing from t_process_step_control, assume the associated procedure should be called
        ---------------------------------------------------

        -- Make New Automatic Tasks
        --
        SELECT enabled
        INTO _result
        FROM cap.t_process_step_control
        WHERE processing_step_name = 'make_new_automatic_tasks';

        If FOUND And _result = 0 Or _bypassDMS Then
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

        If _result > 0 And Not _bypassDMS Then
            CALL cap.make_new_automatic_tasks (_infoOnly => _infoOnly);
        End If;

        -- Make New Tasks From Analysis Broker
        --
        SELECT enabled
        INTO _result
        FROM cap.t_process_step_control
        WHERE processing_step_name = 'make_new_tasks_from_analysis_broker';

        If FOUND And _result = 0 Then
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

        If _result > 0 Then
            CALL cap.make_new_tasks_from_analysis_broker (
                        _infoOnly => _infoOnly,
                        _message => _message,
                        _returnCode => _returnCode,
                        _infoOnlyShowsNewJobsOnly => true);
        End If;

        -- Make New Tasks From DMS
        --
        SELECT enabled
        INTO _result
        FROM cap.t_process_step_control
        WHERE processing_step_name = 'make_new_tasks_from_dms';

        If FOUND And _result = 0 Or _bypassDMS Then
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

        If _result > 0 And Not _bypassDMS Then
            CALL cap.make_new_tasks_from_dms (
                        _message => _message,
                        _returnCode => _returnCode,
                        _loggingEnabled => _loggingEnabled,
                        _infoOnly => _infoOnly);

        End If;

        -- Make New Archive Tasks From DMS
        --
        SELECT enabled
        INTO _result
        FROM cap.t_process_step_control
        WHERE processing_step_name = 'make_new_archive_tasks_from_dms';

        If FOUND And _result = 0 Or _bypassDMS Then
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

        If _result > 0 And Not _bypassDMS Then
            CALL cap.make_new_archive_tasks_from_dms (
                        _message => _message,
                        _returnCode => _returnCode,
                        _loggingEnabled => _loggingEnabled,
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

        DROP TABLE IF EXISTS Tmp_Default_Params;
        DROP TABLE IF EXISTS Tmp_New_Jobs;
    END;

    COMMIT;

    -- Part C: Create capture task job steps
    BEGIN

        SELECT enabled
        INTO _result
        FROM cap.t_process_step_control
        WHERE processing_step_name = 'create_task_steps';

        If FOUND And _result = 0 Then
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

        If _result > 0 Then
            CALL cap.create_task_steps (
                        _message => _message,
                        _returnCode => _returnCode,
                        _maxJobsToProcess => _maxJobsToProcess,
                        _logIntervalThreshold => _logIntervalThreshold,
                        _loggingEnabled => _loggingEnabled,
                        _loopingUpdateInterval => _loopingUpdateInterval,
                        _infoOnly => _infoOnly,
                        _debugMode => _debugMode);

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

        DROP TABLE IF EXISTS Tmp_Jobs;
        DROP TABLE IF EXISTS Tmp_Job_Steps;
        DROP TABLE IF EXISTS Tmp_Job_Step_Dependencies;
        DROP TABLE IF EXISTS Tmp_Job_Parameters;
    END;

    COMMIT;

    -- Part D: Update step states
    BEGIN

        SELECT enabled
        INTO _result
        FROM cap.t_process_step_control
        WHERE processing_step_name = 'update_task_step_states';

        If FOUND And _result = 0 Then
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

        If _result > 0 Then
            CALL cap.update_task_step_states (
                        _message => _message,
                        _returnCode => _returnCode,
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

        DROP TABLE IF EXISTS Tmp_DepTable;
    END;

    COMMIT;

    -- Part E: Update capture task job states
    --         This calls update_task_state, which calls update_dms_dataset_state, which calls update_dms_file_info_xml
    BEGIN

        SELECT enabled
        INTO _result
        FROM cap.t_process_step_control
        WHERE processing_step_name = 'update_task_state';

        If FOUND And _result = 0 Then
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

        If _result > 0 Then
            CALL cap.update_task_state (
                        _bypassDMS => _bypassDMS,
                        _message => _message,
                        _returnCode => _returnCode,
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

        DROP TABLE IF EXISTS Tmp_ChangedJobs;
    END;

    COMMIT;

    -- Part F: Retry capture for datasets that failed capture but for which the dataset state in public.t_dataset is 1=New
    BEGIN

        If _bypassDMS Then
            _result := 0;
            _action := 'Skipping';
        Else
            _result := 1;
            _action := 'Calling';
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s retry_capture_for_dms_reset_tasks', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Task_Context', 'cap');
        End If;

        _currentLocation := 'Call retry_capture_for_dms_reset_tasks';

        If _result > 0 Then
            CALL cap.retry_capture_for_dms_reset_tasks (
                        _message => _message,
                        _returnCode => _returnCode,
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

        DROP TABLE IF EXISTS Tmp_Selected_Jobs;
    END;

    COMMIT;

    If _loggingEnabled Then
        _statusMessage := format('Update context complete: %s seconds elapsed', extract(epoch FROM clock_timestamp() - _startTime));
        CALL public.post_log_entry ('Normal', _statusMessage, 'Update_Task_Context', 'cap');
    End If;

END
$$;


ALTER PROCEDURE cap.update_task_context(IN _bypassdms boolean, IN _maxjobstoprocess integer, IN _logintervalthreshold integer, IN _loggingenabled boolean, IN _loopingupdateinterval integer, IN _infoonly boolean, IN _debugmode boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_task_context(IN _bypassdms boolean, IN _maxjobstoprocess integer, IN _logintervalthreshold integer, IN _loggingenabled boolean, IN _loopingupdateinterval integer, IN _infoonly boolean, IN _debugmode boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.update_task_context(IN _bypassdms boolean, IN _maxjobstoprocess integer, IN _logintervalthreshold integer, IN _loggingenabled boolean, IN _loopingupdateinterval integer, IN _infoonly boolean, IN _debugmode boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateTaskContext or UpdateContext';

