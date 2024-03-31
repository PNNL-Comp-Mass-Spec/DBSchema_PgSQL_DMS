--
-- Name: cleanup_timetable_logs(integer, integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.cleanup_timetable_logs(IN _logretentionhours integer DEFAULT 24, IN _executionlogretentiondays integer DEFAULT 14, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete old log entries from timetable.log and timetable.execution_log
**
**  Arguments:
**    _logRetentionHours            Threshold, in hours, for deleting log entries from timetable.log; required to be at least 2
**    _executionLogRetentionDays    Threshold, in days,  for deleting log entries from timetable.execution_log; required to be at least 1
**    _infoOnly                         When true, show the number of log entries that would be removed or moved
**    _message                          Status message
**    _returnCode                       Return code
**
**  Auth:   mem
**  Date:   03/31/2023 mem - Initial version
**
*****************************************************/
DECLARE
    _logRows int;
    _executionLogRows int;

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

        If Coalesce(_logRetentionHours, 0) < 2 Then
            _logRetentionHours := 2;
        End If;

        If Coalesce(_executionLogRetentionDays, 0) < 1 Then
            _executionLogRetentionDays := 1;
        End If;

        _infoOnly := Coalesce(_infoOnly, false);

        If _infoOnly Then
            ----------------------------------------------------
            -- Count the number of rows to delete in each table
            ----------------------------------------------------

            SELECT COUNT(*)
            INTO _logRows
            FROM timetable.log
            WHERE log_level = 'INFO' AND
                  ts < CURRENT_TIMESTAMP - make_interval(hours => _logRetentionHours);

            SELECT COUNT(*)
            INTO _executionLogRows
            FROM timetable.execution_log
            WHERE last_run < CURRENT_TIMESTAMP - make_interval(days => _executionLogRetentionDays);

            _message := Format('Would delete %s %s from timetable.log and %s %s from timetable.execution_log',
                               _logRows,          public.check_plural(_logRows,          'row', 'rows'),
                               _executionLogRows, public.check_plural(_executionLogRows, 'row', 'rows'));

            RAISE INFO '%', _message;
            RETURN;
        End If;

        DELETE FROM timetable.log
        WHERE log_level = 'INFO' AND
              ts < CURRENT_TIMESTAMP - make_interval(hours => _logRetentionHours);
        --
        GET DIAGNOSTICS _logRows = ROW_COUNT;

        DELETE FROM timetable.execution_log
        WHERE last_run < CURRENT_TIMESTAMP - make_interval(days => _executionLogRetentionDays);
        --
        GET DIAGNOSTICS _executionLogRows = ROW_COUNT;

        _message := Format('Deleted %s %s from timetable.log and %s %s from timetable.execution_log',
                               _logRows,          public.check_plural(_logRows,          'row', 'rows'),
                               _executionLogRows, public.check_plural(_executionLogRows, 'row', 'rows'));

        RAISE INFO '%', _message;

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


ALTER PROCEDURE public.cleanup_timetable_logs(IN _logretentionhours integer, IN _executionlogretentiondays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

