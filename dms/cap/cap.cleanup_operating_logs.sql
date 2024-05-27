--
-- Name: cleanup_operating_logs(integer, integer, boolean, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.cleanup_operating_logs(IN _infoholdoffweeks integer DEFAULT 2, IN _logretentionintervaldays integer DEFAULT 180, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete old Info and Warn entries from cap.t_log_entries if they are older than the threshold
**
**      Move old log entries and event entries to historic log tables if they are older than the threshold
**
**  Arguments:
**    _infoHoldoffWeeks             Threshold, in weeks, for deleting old Info and Warn entries (minimum:  1 week)
**    _logRetentionIntervalDays     Threshold, in days, for moving old log and event entries    (minimum: 14 days)
**    _infoOnly                     When true, show the number of entries in each table that would be deleted or archived
**    _message                      Status message
**    _returnCode                   Return code
**
**  Auth:   mem
**  Date:   10/04/2011 mem - Initial version
**          02/23/2016 mem - Add set XACT_ABORT on
**          08/25/2022 mem - Use new column name in T_Log_Entries
**          10/07/2022 mem - Ported to PostgreSQL
**          10/22/2022 mem - Directly pass value to function argument
**          02/15/2023 mem - Add Commit statement
**          04/02/2023 mem - Rename procedure and functions
**          05/12/2023 mem - Rename variables
**          07/11/2023 mem - Use COUNT(entry_id) instead of COUNT(*)
**          09/07/2023 mem - Align assignment statements
**          05/26/2024 mem - Remove Commit statements
**                         - Pass procedure name and schema to local_error_handler() since multiple schemas have procedure cleanup_operating_logs
**                         - Show a debug message that includes the date cutoff for deleting Info and Warn entries
**
*****************************************************/
DECLARE
    _currentLocation text := 'Start';
    _infoCutoffDateTime timestamp;
    _dateThreshold text;
    _matchCount int;
    _deleteCount int;

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

        If Coalesce(_logRetentionIntervalDays, 0) < 14 Then
            _logRetentionIntervalDays := 14;
        End If;

        _infoCutoffDateTime := CURRENT_TIMESTAMP - make_interval(weeks => _infoHoldoffWeeks);
        _dateThreshold      := public.timestamp_text(_infoCutoffDateTime);

        ----------------------------------------------------
        -- Delete Info and Warn entries posted more than _infoHoldoffWeeks weeks ago
        --
        -- Typically only public.t_log_entries will have Info or Warn log messages,
        -- so the following queries will likely not match any rows
        ----------------------------------------------------

        BEGIN
            _currentLocation := 'Delete Info and Warn entries';

            If _infoOnly Then
                SELECT COUNT(entry_id)
                INTO _matchCount
                FROM cap.t_log_entries
                WHERE (entered < _infoCutoffDateTime) AND
                      (type = 'info' OR
                      (type = 'warn' AND message = 'Dataset Quality tool is not presently active') );

                If _matchCount > 0 Then
                    RAISE INFO 'Would delete % rows from cap.t_log_entries since Info or Warn messages older than %', _matchCount, _dateThreshold;
                Else
                    RAISE INFO 'All Info entries in cap.% are newer than %', RPAD('t_log_entries', 26, ' '), _dateThreshold;
                End If;

            Else
                RAISE INFO 'Deleting Info and Warn entries from cap.t_log_entries where entered < %', public.timestamp_text(_infoCutoffDateTime);

                DELETE FROM cap.t_log_entries
                WHERE (entered < _infoCutoffDateTime) AND
                      (type = 'info' OR
                      (type = 'warn' AND message = 'Dataset Quality tool is not presently active') );
                --
                GET DIAGNOSTICS _deleteCount = ROW_COUNT;

                If _deleteCount > 0 Then
                    RAISE INFO 'Deleted % rows from cap.t_log_entries since Info or Warn messages older than %', _deleteCount, _dateThreshold;
                End If;
            End If;
        END;

        ----------------------------------------------------
        -- Move old log entries and event entries to historic log tables
        ----------------------------------------------------

        _currentLocation := 'Call cap.move_capture_entries_to_history';

        RAISE INFO 'Calling cap.move_capture_entries_to_history';

        CALL cap.move_capture_entries_to_history (_logRetentionIntervalDays, _infoOnly);

        If _infoOnly Then
            _message := 'See the output window for status messages';
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation,
                        _callingProcName     => 'cleanup_operating_logs',
                        _callingProcSchema   => 'cap',
                        _logError            => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;
END
$$;


ALTER PROCEDURE cap.cleanup_operating_logs(IN _infoholdoffweeks integer, IN _logretentionintervaldays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE cleanup_operating_logs(IN _infoholdoffweeks integer, IN _logretentionintervaldays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.cleanup_operating_logs(IN _infoholdoffweeks integer, IN _logretentionintervaldays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'CleanupOperatingLogs';

