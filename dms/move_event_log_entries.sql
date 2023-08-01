--
-- Name: move_event_log_entries(integer, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.move_event_log_entries(IN _intervaldays integer DEFAULT 365, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Move entries from public.t_event_log into the historic log table (logdms.t_event_log)
**
**  Arguments:
**    _intervalDays     Threshold, in days, for removing entries from t_event_log; required to be at least 32
**    _infoOnly         When true, show the number of log entries that would be removed or moved
**
**  Auth:   grk
**  Date:   07/13/2009
**          10/04/2011 mem - Removed _dBName parameter
**          07/31/2012 mem - Renamed Historic Log DB from DMSHistoricLog1 to DMSHistoricLog
**          06/08/2022 mem - Rename column Index to Event_ID
**          08/01/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _cutoffDateTime timestamp;
    _rowCount int;
BEGIN
    -- Require that _intervalDays be at least 32
    If Coalesce(_intervalDays, 0) < 32 Then
        _intervalDays := 32;
    End If;

    _infoOnly := Coalesce(_infoOnly, false);

    _cutoffDateTime := CURRENT_TIMESTAMP - make_interval(days => _intervalDays);

    If _infoOnly Then
        RAISE INFO '';

        SELECT COUNT(event_id)
        INTO _rowCount
        FROM public.t_event_log
        WHERE entered < _cutoffDateTime;

        If _rowCount > 0 Then
            RAISE INFO 'Would move % old event log % from public.t_event_log to logdms.t_event_log (using threshold %)',
                        _rowCount,
                        public.check_plural(_rowCount, 'entry', 'entries'),
                        public.timestamp_text(_cutoffDateTime);
        Else
            RAISE INFO 'No event log entries older than % were found in public.t_event_log',
                        public.timestamp_text(_cutoffDateTime);
        End If;

        RETURN;
    End If;

    -- Copy entries into the historic log tables
    --
    INSERT INTO logdms.t_event_log( event_id,
                                    target_type,
                                    target_id,
                                    target_state,
                                    prev_target_state,
                                    entered,
                                    entered_by )
    SELECT event_id,
           target_type,
           target_id,
           target_state,
           prev_target_state,
           entered,
           entered_by
    FROM public.t_event_log
    WHERE entered < _cutoffDateTime
    ORDER BY event_id;

    -- Remove the old entries from t_event_log
    --
    DELETE FROM public.t_event_log
    WHERE entered < _cutoffDateTime;

END
$$;


ALTER PROCEDURE public.move_event_log_entries(IN _intervaldays integer, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE move_event_log_entries(IN _intervaldays integer, IN _infoonly boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.move_event_log_entries(IN _intervaldays integer, IN _infoonly boolean) IS 'MoveEventLogEntries';

