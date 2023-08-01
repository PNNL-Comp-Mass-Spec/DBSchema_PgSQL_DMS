--
-- Name: cleanup_operating_logs(integer, integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.cleanup_operating_logs(IN _logretentionintervalhours integer DEFAULT 336, IN _eventlogretentionintervaldays integer DEFAULT 365, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Move entries from public.t_log_entries into the historic log table (logdms.t_log_entries)
**      Move entries from public.t_event_log into the historic log table (logdms.t_event_log)
**
**  Arguments:
**    _logRetentionIntervalHours        Threshold, in hours, to use when moving move entries from t_log_entries; required to be at least 120
**    _eventLogRetentionIntervalDays    Threshold, in days, for removing entries from t_event_log; required to be at least 32
**    _infoOnly                         When true, show the number of log entries that would be removed or moved
**
**  Auth:   mem
**  Date:   10/04/2011 mem - Initial version
**          07/31/2012 mem - Renamed Historic Log DB from DMSHistoricLog1 to DMSHistoricLog
**          11/21/2012 mem - Removed call to Move_Analysis_Log_Entries
**          02/23/2016 mem - Add set XACT_ABORT on
**          06/09/2022 mem - Update default log retention interval
**          08/01/2023 mem - Ported to PostgreSQL
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

        _infoOnly := Coalesce(_infoOnly, false);

        ----------------------------------------------------
        -- Move old log entries from t_log_entries to the historic log schema (logdms.t_log_entries)
        ----------------------------------------------------

        _currentLocation := 'Call Move_Historic_Log_Entries';

        CALL public.move_historic_log_entries (_logRetentionIntervalHours, _infoOnly => _infoOnly);

        ----------------------------------------------------
        -- Move old events from t_event_log to the historic log schema (logdms.t_event_log)
        ----------------------------------------------------

        _currentLocation := 'Call Move_Event_Log_Entries';

        CALL public.move_event_log_entries (_eventLogRetentionIntervalDays, _infoOnly => _infoOnly);

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


ALTER PROCEDURE public.cleanup_operating_logs(IN _logretentionintervalhours integer, IN _eventlogretentionintervaldays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE cleanup_operating_logs(IN _logretentionintervalhours integer, IN _eventlogretentionintervaldays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.cleanup_operating_logs(IN _logretentionintervalhours integer, IN _eventlogretentionintervaldays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'CleanupOperatingLogs';

