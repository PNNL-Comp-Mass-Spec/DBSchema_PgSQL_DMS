--
-- Name: cleanup_operating_logs(integer, integer, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.cleanup_operating_logs(IN _infoholdoffweeks integer DEFAULT 4, IN _logretentionintervaldays integer DEFAULT 365, IN _message text DEFAULT ''::text, IN _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Move old log entries and event entries to historic log tables (in the logsw schema)
**
**  Arguments:
**    _infoHoldoffWeeks             Threshold, in weeks, for removing non-noteworthy log entries from sw.t_log_entries
**    _logRetentionIntervalDays     Threshold, in days, to use when moving old entries; required to be at least 32

**  Auth:   mem
**  Date:   10/04/2011 mem - Initial version
**          02/23/2016 mem - Add set XACT_ABORT on
**          08/25/2022 mem - Use new column name in T_Log_Entries
**          08/01/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _message text;
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

        If Coalesce(_infoHoldoffWeeks, 0) < 1 Then
            _infoHoldoffWeeks := 1;
        End If;

        If Coalesce(_logRetentionIntervalDays, 0) < 32 Then
            _logRetentionIntervalDays := 32;
        End If;

        ----------------------------------------------------
        -- Delete "Resuming jobs" and "Deleted job" entries posted more than _infoHoldoffWeeks weeks ago
        ----------------------------------------------------

        _currentLocation := 'Delete non-noteworthy log entries';

        DELETE FROM sw.t_log_entries
        WHERE Entered < CURRENT_TIMESTAMP - make_interval(weeks => _infoHoldoffWeeks) AND
              (message SIMILAR TO 'Resuming [0-9]%job%' OR
               message LIKE 'Deleted job % from sw.t_jobs');

        ----------------------------------------------------
        -- Move old log entries and event entries to logsw.t_job_events, logsw.t_job_step_events, and logsw.t_log_entries
        ----------------------------------------------------

        _currentLocation := 'Call sw.move_entries_to_history';

        CALL sw.move_entries_to_history (
                        _logRetentionIntervalDays,
                        _message => _message,
                        _returnCode => _returnCode);

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

END
$$;


ALTER PROCEDURE sw.cleanup_operating_logs(IN _infoholdoffweeks integer, IN _logretentionintervaldays integer, IN _message text, IN _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE cleanup_operating_logs(IN _infoholdoffweeks integer, IN _logretentionintervaldays integer, IN _message text, IN _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.cleanup_operating_logs(IN _infoholdoffweeks integer, IN _logretentionintervaldays integer, IN _message text, IN _returncode text) IS 'CleanupOperatingLogs';

