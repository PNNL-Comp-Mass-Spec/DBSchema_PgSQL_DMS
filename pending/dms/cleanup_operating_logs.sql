--
CREATE OR REPLACE PROCEDURE public.cleanup_operating_logs
(
    _logRetentionIntervalHours int = 336,
    _eventLogRetentionIntervalDays int = 365,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Deletes Info entries from T_Log_Entries if they are more than _logRetentionIntervalHours hours old
**
**      Moves old log entries and event entries to tables in the historic log schema (logdms)
**
**  Auth:   mem
**  Date:   10/04/2011 mem - Initial version
**          07/31/2012 mem - Renamed Historic Log DB from DMSHistoricLog1 to DMSHistoricLog
**          11/21/2012 mem - Removed call to MoveAnalysisLogEntries
**          02/23/2016 mem - Add set XACT_ABORT on
**          06/09/2022 mem - Update default log retention interval
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _callingProcName text;
    _currentLocation text := 'Start';

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        If Coalesce(_logRetentionIntervalHours, 0) < 120 Then
            _logRetentionIntervalHours := 120;
        End If;

        If Coalesce(_eventLogRetentionIntervalDays, 0) < 32 Then
            _eventLogRetentionIntervalDays := 32;
        End If;

        ----------------------------------------------------
        -- Move old log entries from t_log_entries to the historic log schema (logdms.t_log_entries)
        ----------------------------------------------------
        --
        _currentLocation := 'Call MoveHistoricLogEntries';

        CALL move_historic_log_entries _logRetentionIntervalHours

        ----------------------------------------------------
        -- Move old events from t_event_log to the historic log schema (logdms.t_event_log)
        ----------------------------------------------------
        --
        _currentLocation := 'Call MoveEventLogEntries';

        CALL move_event_log_entries _eventLogRetentionIntervalDays

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

END
$$;

COMMENT ON PROCEDURE public.cleanup_operating_logs IS 'CleanupOperatingLogs';
