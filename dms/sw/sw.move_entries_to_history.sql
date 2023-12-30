--
-- Name: move_entries_to_history(integer, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.move_entries_to_history(IN _intervaldays integer DEFAULT 365, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Move old log entries and event log entries to historic log tables (in the logsw schema)
**
**  Arguments:
**    _intervalDays     Threshold, in days, to use when moving old entries; required to be at least 32
**    _infoOnly         When true, show the number of entries that would be moved
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   07/12/2011 mem - Initial version
**          10/04/2011 mem - Removed _dBName parameter
**          08/25/2022 mem - Use new column name in T_Log_Entries
**          08/01/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _cutoffDateTime timestamp;
    _rowCount int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    -- Require that _intervalDays be at least 32

    If Coalesce(_intervalDays, 0) < 32 Then
        _intervalDays := 32;
    End If;

    _infoOnly := Coalesce(_infoOnly, false);

    _cutoffDateTime := CURRENT_TIMESTAMP - make_interval(days => _intervalDays);

    ----------------------------------------------------------
    -- Copy Job_Events entries into historic log table logsw.t_job_events
    ----------------------------------------------------------

    BEGIN
        If _infoOnly Then
            RAISE INFO '';

            SELECT COUNT(event_id)
            INTO _rowCount
            FROM sw.t_job_events
            WHERE entered < _cutoffDateTime;

            If _rowCount > 0 Then
                RAISE INFO 'Would move % old event log % from sw.t_job_events to logsw.t_job_events (using threshold %)',
                            _rowCount,
                            public.check_plural(_rowCount, 'entry', 'entries'),
                            public.timestamp_text(_cutoffDateTime);
            Else
                RAISE INFO 'No event log entries older than % were found in sw.t_job_events',
                            public.timestamp_text(_cutoffDateTime);
            End If;

        Else
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
                        _callingProcLocation => 'Moving rows in sw.t_job_events to the historic log tables', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        RETURN;
    END;

    ----------------------------------------------------------
    -- Copy Job_Step_Events entries into historic log table logsw.t_job_step_events
    ----------------------------------------------------------

    BEGIN
        If _infoOnly Then
            SELECT COUNT(event_id)
            INTO _rowCount
            FROM sw.t_job_step_events
            WHERE entered < _cutoffDateTime;

            If _rowCount > 0 Then
                RAISE INFO 'Would move % old event log % from sw.t_job_step_events to logsw.t_job_step_events (using threshold %)',
                            _rowCount,
                            public.check_plural(_rowCount, 'entry', 'entries'),
                            public.timestamp_text(_cutoffDateTime);
            Else
                RAISE INFO 'No event log entries older than % were found in sw.t_job_step_events',
                            public.timestamp_text(_cutoffDateTime);
            End If;

        Else
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
            ORDER BY event_id;

            -- Remove the old entries
            --
            DELETE FROM sw.t_job_step_events
            WHERE entered < _cutoffDateTime;
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
                        _callingProcLocation => 'Moving rows in sw.t_job_step_events to the historic log tables', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        RETURN;
    END;

    ----------------------------------------------------------
    -- Copy Job_Step_Processing_Log entries into historic log table logsw.t_job_step_processing_log
    ----------------------------------------------------------

    BEGIN
        If _infoOnly Then
            SELECT COUNT(event_id)
            INTO _rowCount
            FROM sw.t_job_step_processing_log
            WHERE entered < _cutoffDateTime;

            If _rowCount > 0 Then
                RAISE INFO 'Would move % old processing log % from sw.t_job_step_processing_log to logsw.t_job_step_processing_log (using threshold %)',
                            _rowCount,
                            public.check_plural(_rowCount, 'entry', 'entries'),
                            public.timestamp_text(_cutoffDateTime);
            Else
                RAISE INFO 'No processing log entries older than % were found in sw.t_job_step_processing_log',
                            public.timestamp_text(_cutoffDateTime);
            End If;

        Else
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
                        _callingProcLocation => 'Moving rows in sw.t_job_step_processing_log to the historic log tables', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        RETURN;
    END;

    ----------------------------------------------------------
    -- Copy Log entries into historic log table logsw.t_log_entries
    ----------------------------------------------------------

    BEGIN
        If _infoOnly Then
            SELECT COUNT(entry_id)
            INTO _rowCount
            FROM sw.t_log_entries
            WHERE entered < _cutoffDateTime;

            If _rowCount > 0 Then
                RAISE INFO 'Would move % old log % from sw.t_log_entries to logsw.t_log_entries (using threshold %)',
                            _rowCount,
                            public.check_plural(_rowCount, 'entry', 'entries'),
                            public.timestamp_text(_cutoffDateTime);
            Else
                RAISE INFO 'No log entries older than % were found in sw.t_log_entries',
                            public.timestamp_text(_cutoffDateTime);
            End If;

        Else
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
                        _callingProcLocation => 'Moving rows in sw.t_log_entries to the historic log tables', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        RETURN;
    END;
END
$$;


ALTER PROCEDURE sw.move_entries_to_history(IN _intervaldays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE move_entries_to_history(IN _intervaldays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.move_entries_to_history(IN _intervaldays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'MoveEntriesToHistory';

