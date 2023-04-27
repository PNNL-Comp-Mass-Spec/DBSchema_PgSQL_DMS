--
CREATE OR REPLACE PROCEDURE sw.cleanup_operating_logs
(
    _infoHoldoffWeeks int = 4,
    _logRetentionIntervalDays int = 365
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Move old log entries and event entries to DMSHistoricLogPipeline
**
**  Auth:   mem
**  Date:   10/04/2011 mem - Initial version
**          02/23/2016 mem - Add set XACT_ABORT on
**          08/25/2022 mem - Use new column name in T_Log_Entries
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _message text;
    _callingProcName text;
    _currentLocation text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    _message := '';

    _currentLocation := 'Start';

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

        ----------------------------------------------------
        -- Delete Info and Warn entries posted more than _infoHoldoffWeeks weeks ago
        ----------------------------------------------------
        --
        _currentLocation := 'Delete non-noteworthy log entries';

        DELETE FROM sw.t_log_entries
        WHERE Entered < CURRENT_TIMESTAMP - make_interval(weeks => _infoHoldoffWeeks) AND
              (message SIMILAR TO 'Resuming "0-9"%job%' OR
               message LIKE 'Deleted job % from sw.t_jobs')
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        ----------------------------------------------------
        -- Move old log entries and event entries to DMSHistoricLogPipeline
        ----------------------------------------------------
        --
        _currentLocation := 'Call sw.move_entries_to_history';

        Call sw.move_entries_to_history _logRetentionIntervalDays

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
    END;

END
$$;

COMMENT ON PROCEDURE sw.cleanup_operating_logs IS 'CleanupOperatingLogs';
