--
CREATE OR REPLACE PROCEDURE public.move_event_log_entries
(
    _intervalDays int = 365
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Move log entries from event log into the historic log table (logdms.t_log_entries )
**      Moves entries older than _intervalDays days
**
**  Auth:   grk
**  Date:   07/13/2009
**          10/04/2011 mem - Removed _dBName parameter
**          07/31/2012 mem - Renamed Historic Log DB from DMSHistoricLog1 to DMSHistoricLog
**          06/08/2022 mem - Rename column Index to Event_ID
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _cutoffDateTime timestamp;
BEGIN
    -- Require that _intervalDays be at least 32
    If Coalesce(_intervalDays, 0) < 32 Then
        _intervalDays := 32;
    End If;

    _cutoffDateTime := CURRENT_TIMESTAMP - make_interval(days => _intervalDays);

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

COMMENT ON PROCEDURE public.move_event_log_entries IS 'MoveEventLogEntries';
