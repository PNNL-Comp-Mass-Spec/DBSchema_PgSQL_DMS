--
CREATE OR REPLACE PROCEDURE sw.move_entries_to_history
(
    _intervalDays int = 365,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Move entries from log tables into historic log tables (insert and then delete)
**      Moves entries older than _intervalDays days
**
**  Auth:   mem
**  Date:   07/12/2011 mem - Initial version
**          10/04/2011 mem - Removed _dBName parameter
**          08/25/2022 mem - Use new column name in T_Log_Entries
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _cutoffDateTime timestamp;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode:= '';


    -- Require that _intervalDays be at least 32
    If Coalesce(_intervalDays, 0) < 32 Then
        _intervalDays := 32;
    End If;

    _cutoffDateTime := CURRENT_TIMESTAMP - make_interval(days => _intervalDays);

    ----------------------------------------------------------
    -- Copy Job_Events entries into historic log tables
    ----------------------------------------------------------
    --
    BEGIN

        INSERT INTO logsw.t_job_events( event_id,
                                        job,
                                        target_state,
                                        prev_target_state,
                                        entered,
                                        entered_by )
        SELECT event_id,
               job,
               target_state,
               prev_target_state,
               entered,
               entered_by
        FROM sw.t_job_events
        WHERE entered < _cutoffDateTime
        ORDER BY event_id;

        -- Remove the old entries
        --
        DELETE FROM sw.t_job_events
        WHERE entered < _cutoffDateTime;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => 'Moving rows in t_job_events to the historic log tables', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        RETURN;
    END;


    ----------------------------------------------------------
    -- Copy Job_Step_Events entries into database DMSHistoricLogPipeline
    ----------------------------------------------------------
    --
    BEGIN

        INSERT INTO logsw.t_job_step_events( event_id,
                                             job,
                                             step,
                                             target_state,
                                             prev_target_state,
                                             entered,
                                             entered_by )
        SELECT event_id,
               job,
               step,
               target_state,
               prev_target_state,
               entered,
               entered_by
        FROM sw.t_job_step_events
        WHERE entered < _cutoffDateTime
        ORDER BY event_id

        -- Remove the old entries
        --
        DELETE FROM sw.t_job_step_events
        WHERE entered < _cutoffDateTime;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => 'Moving rows in t_job_step_events to the historic log tables', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        RETURN;
    END;

    ----------------------------------------------------------
    -- Copy Job_Step_Processing_Log entries into database DMSHistoricLogPipeline
    ----------------------------------------------------------
    --
    BEGIN

        INSERT INTO logsw.t_job_step_processing_log( event_id,
                                                     job,
                                                     step,
                                                     processor,
                                                     entered,
                                                     entered_by )
        SELECT event_id,
               job,
               step,
               processor,
               entered,
               entered_by
        FROM sw.t_job_step_processing_log
        WHERE entered < _cutoffDateTime
        ORDER BY event_id;

        -- Remove the old entries
        --
        DELETE FROM sw.t_job_step_processing_log
        WHERE entered < _cutoffDateTime;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => 'Moving rows in t_job_step_processing_log to the historic log tables', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        RETURN;
    END;

    ----------------------------------------------------------
    -- Copy Log entries into database DMSHistoricLogPipeline
    ----------------------------------------------------------
    --
    BEGIN

        INSERT INTO logsw.t_log_entries( entry_id,
                                         posted_by,
                                         Entered,
                                         type,
                                         message,
                                         entered_by )
        SELECT entry_id,
               posted_by,
               Entered,
               type,
               message,
               entered_by
        FROM sw.t_log_entries
        WHERE Entered < _cutoffDateTime
        ORDER BY entry_id;

        -- Remove the old entries
        --
        DELETE FROM sw.t_log_entries
        WHERE Entered < _cutoffDateTime;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => 'Moving rows in t_log_entries to the historic log tables', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        RETURN;

    END;
END
$$;

COMMENT ON PROCEDURE sw.move_entries_to_history IS 'MoveEntriesToHistory';
