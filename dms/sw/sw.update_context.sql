--
-- Name: update_context(boolean, integer, integer, boolean, integer, boolean, integer, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.update_context(IN _bypassdms boolean DEFAULT false, IN _maxjobstoprocess integer DEFAULT 0, IN _logintervalthreshold integer DEFAULT 15, IN _loggingenabled boolean DEFAULT false, IN _loopingupdateinterval integer DEFAULT 5, IN _infoonly boolean DEFAULT false, IN _infolevel integer DEFAULT 0, IN _debugmode boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update context under which job steps are assigned
**
**  Arguments:
**    _bypassDMS                If false, lookup the bypass mode in sw.t_process_step_control; when _bypassDMS is true, do not import new jobs from public.t_analysis_job and do not synchronize the sw schema tables with the public schema tables
**    _maxJobsToProcess         Maximum number of jobs to process
**    _logIntervalThreshold     If this procedure runs longer than this threshold (in seconds), status messages will be posted to the log
**    _loggingEnabled           Set to true to immediately enable progress logging; if false, logging will auto-enable if _logIntervalThreshold seconds elapse
**    _loopingUpdateInterval    Seconds between detailed logging while looping sets of jobs or steps to process
**    _infoOnly                 True to preview changes that would be made
**    _infoLevel                When _infoOnly is true, 1 to preview changes, 2 to add new jobs but do not create job steps
**    _debugMode                When true, show additional information when calling sw.add_new_jobs and sw.create_job_steps (which calls several procedures, including sw.create_steps_for_job, sw.finish_job_creation, and sw.move_jobs_to_main_tables)
**                              Additionally, sw.move_jobs_to_main_tables stores the contents of the temporary tables in the following tables when _infoOnly is false and _debugMode is true
**                                sw.T_Tmp_New_Jobs
**                                sw.T_Tmp_New_Job_Steps
**                                sw.T_Tmp_New_Job_Step_Dependencies
**                                sw.T_Tmp_New_Job_Parameters
**
**  Auth:   grk
**  Date:   05/30/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          01/09/2009 mem - Added parameter _infoOnly (http://prismtrac.pnl.gov/trac/ticket/713)
**          01/17/2009 mem - Now calling Sync_Job_Info (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**          02/19/2009 grk - Added call to Remove_DMS_Deleted_Jobs (Ticket #723)
**          06/02/2009 mem - Added parameter _maxJobsToProcess (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          06/03/2009 mem - Added parameters _logIntervalThreshold, _loggingEnabled, and _loopingUpdateInterval
**          06/04/2009 mem - Added Try/Catch error handling
**                         - Now using T_Process_Step_Control to determine whether or not to Update states in DMS
**          06/05/2009 mem - Added expanded support for T_Process_Step_Control
**          03/21/2011 mem - Added parameter _debugMode; now passing _infoOnly to AddNewJobs
**          01/12/2012 mem - Now passing _infoOnly to UpdateJobState
**          05/02/2015 mem - Now calling Auto_Fix_Failed_Jobs
**          05/28/2015 mem - No longer calling Import_Job_Processors
**          11/20/2015 mem - Now calling Update_Actual_CPU_Loading
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/30/2018 mem - Update comments
**          08/03/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
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

    -- Part A: Validate inputs, Remove Deleted Jobs, Add New Jobs, Hold/Resume/Reset jobs
    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _bypassDMS             := Coalesce(_bypassDMS, false);
        _maxJobsToProcess      := Coalesce(_maxJobsToProcess, 0);

        _logIntervalThreshold  := Coalesce(_logIntervalThreshold, 15);
        _loggingEnabled        := Coalesce(_loggingEnabled, false);
        _loopingUpdateInterval := Coalesce(_loopingUpdateInterval, 5);

        _infoOnly              := Coalesce(_infoOnly, false);
        _infoLevel             := Coalesce(_infoLevel, 0);
        _debugMode             := Coalesce(_debugMode, false);

        If _logIntervalThreshold = 0 Then
            _loggingEnabled := true;
        End If;

        -- Lookup the log level in sw.t_process_step_control

        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE processing_step_name = 'LogLevel';

        -- Set _loggingEnabled if the LogLevel is 2 or higher
        If FOUND And Coalesce(_result, 0) >= 2 Then
            _loggingEnabled := true;
        End If;

        If Not _bypassDMS Then

            -- See if DMS Updating is disabled in sw.t_process_step_control

            SELECT enabled
            INTO _result
            FROM sw.t_process_step_control
            WHERE processing_step_name = 'UpdateDMS';

            If FOUND And Coalesce(_result, 1) = 0 Then
                _bypassDMS := true;
            End If;
        End If;

        ---------------------------------------------------
        -- Call the various procedures for performing updates
        -- If an option is missing from t_process_step_control, assume the associated procedure should be called
        ---------------------------------------------------

        -- Step 1: Remove jobs deleted from DMS
        --
        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE processing_step_name = 'remove_dms_deleted_jobs';

        If FOUND And _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
            _result := 1;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s remove_dms_deleted_jobs', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call remove_dms_deleted_jobs';

        If _result > 0 Then
            CALL sw.remove_dms_deleted_jobs (
                        _bypassDMS,
                        _message => _message,
                        _returnCode => _returnCode,
                        _maxJobsToProcess => _maxJobsToProcess);
        End If;

        -- Step 2: Add new jobs, hold/resume/reset existing jobs
        --
        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE processing_step_name = 'add_new_jobs';

        If FOUND And _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
            _result := 1;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s add_new_jobs', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call add_new_jobs';

        If _result > 0 Then
            CALL sw.add_new_jobs (
                        _bypassDMS,
                        _message => _message,
                        _returnCode => _returnCode,
                        _maxJobsToProcess => _maxJobsToProcess,
                        _logIntervalThreshold => _LogIntervalThreshold,
                        _loggingEnabled => _LoggingEnabled,
                        _loopingUpdateInterval => _LoopingUpdateInterval,
                        _infoOnly => _infoOnly,
                        _infoLevel => _infoLevel,
                        _debugMode => _DebugMode);

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

    -- Part B: Import Processors and Sync Job Info
    BEGIN

        -- Step 3: Import Processors
        --
        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE processing_step_name = 'import_processors';

        If FOUND And _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
            _result := 1;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s import_processors', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call import_processors';

        If _result > 0 Then
            CALL sw.import_processors (
                        _bypassDMS,
                        _message => _message,
                        _returnCode => _returnCode);
        End If;

        /*
        ---------------------------------------------------
        -- Deprecated in May 2015:
        -- Import Job Processors
        --
        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE processing_step_name = 'import_job_processors';

        If FOUND And _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
            _result := 1;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s import_job_processors', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call import_job_processors';

        If _result > 0 Then
            CALL sw.import_job_processors (_bypassDMS, _message => _message, _returnCode => _returnCode);
        End If;
        */

        -- Step 4: Sync Job Info
        --
        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE processing_step_name = 'sync_job_info';

        If FOUND And _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
            _result := 1;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s sync_job_info', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call sync_job_info';

        If _result > 0 Then
            CALL sw.sync_job_info (
                        _bypassDMS,
                        _message => _message,
                        _returnCode => _returnCode);
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
        WHERE processing_step_name = 'create_job_steps';

        If FOUND And _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
            _result := 1;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s create_job_steps', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call create_job_steps';

        If _result > 0 Then
            CALL sw.create_job_steps (
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
    END;

    COMMIT;

    -- Part D
    BEGIN

        -- Step 6: Update step states
        --
        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE processing_step_name = 'update_step_states';

        If FOUND And _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
            _result := 1;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s update_step_states', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call update_step_states';

        If _result > 0 Then
            CALL sw.update_step_states (
                        _infoOnly => _infoOnly,
                        _maxJobsToProcess => _maxJobsToProcess,
                        _loopingUpdateInterval => _loopingUpdateInterval,
                        _message => _message,
                        _returnCode => _returnCode);
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
        WHERE processing_step_name = 'update_job_state';

        If FOUND And _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
            _result := 1;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s update_job_state', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call update_job_state';

        If _result > 0 Then
            CALL sw.update_job_state (
                        _bypassDMS,
                        _maxJobsToProcess => _maxJobsToProcess,
                        _loopingUpdateInterval => _loopingUpdateInterval,
                        _infoOnly => _infoOnly,
                        _message => _message,               -- Output
                        _returnCode => _returnCode          -- Output
                        );
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

    -- Part F
    BEGIN

        -- Step 8: Update CPU loading and memory usage
        --
        SELECT enabled
        INTO _result
        FROM sw.t_process_step_control
        WHERE processing_step_name = 'update_cpu_loading';

        If FOUND And _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
            _result := 1;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s update_cpu_loading', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call update_cpu_loading';

        If _result > 0 Then
            -- First update actual_cpu_load in sw.t_job_steps
            CALL sw.update_actual_cpu_loading (_infoOnly => false);

            -- Now update cpus_available in sw.t_machines
            CALL sw.update_cpu_loading (_message => _message, _returnCode => _returnCode);
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
        WHERE processing_step_name = 'auto_fix_failed_jobs';

        If FOUND And _result = 0 Then
            _action := 'Skipping';
        Else
            _action := 'Calling';
            _result := 1;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := format('%s auto_fix_failed_jobs', _action);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Context', 'sw');
        End If;

        _currentLocation := 'Call auto_fix_failed_jobs';

        If _result > 0 Then
            CALL sw.auto_fix_failed_jobs (
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
    END;

    COMMIT;

    If _loggingEnabled Then
        _statusMessage := format('Update context complete: %s seconds elapsed', extract(epoch FROM clock_timestamp() - _startTime));
        CALL public.post_log_entry ('Normal', _statusMessage, 'Update_Context', 'sw');
    End If;

END
$$;


ALTER PROCEDURE sw.update_context(IN _bypassdms boolean, IN _maxjobstoprocess integer, IN _logintervalthreshold integer, IN _loggingenabled boolean, IN _loopingupdateinterval integer, IN _infoonly boolean, IN _infolevel integer, IN _debugmode boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_context(IN _bypassdms boolean, IN _maxjobstoprocess integer, IN _logintervalthreshold integer, IN _loggingenabled boolean, IN _loopingupdateinterval integer, IN _infoonly boolean, IN _infolevel integer, IN _debugmode boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.update_context(IN _bypassdms boolean, IN _maxjobstoprocess integer, IN _logintervalthreshold integer, IN _loggingenabled boolean, IN _loopingupdateinterval integer, IN _infoonly boolean, IN _infolevel integer, IN _debugmode boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateContext';

