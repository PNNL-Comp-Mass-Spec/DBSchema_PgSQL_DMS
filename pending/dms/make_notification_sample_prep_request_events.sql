--
CREATE OR REPLACE PROCEDURE public.make_notification_sample_prep_request_events
(
    _infoOnly boolean = false,
    _showDebug boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds sample prep request notification events to notification event table
**
**  Arguments:
**
**  Auth:   grk
**  Date:   03/30/2010
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _eventCount int := 0;
    _window timestamp;
    _now timestamp;
    _eventInfo record;
BEGIN

    _infoOnly := Coalesce(_infoOnly, false);
    _showDebug := Coalesce(_showDebug, false);

    ---------------------------------------------------
    -- Window for sample prep request activity
    ---------------------------------------------------

    _window := CURRENT_TIMESTAMP - INTERVAL '7 days'

    ---------------------------------------------------
    -- Earlier than batch creation window
    -- (default for datasets with null start time)
    ---------------------------------------------------

    _now := CURRENT_TIMESTAMP;

    ---------------------------------------------------
    -- Temp table for events to be added
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_NewEvents (
        Target_ID int,
        Event_Type int
    )

    INSERT INTO Tmp_NewEvents
    SELECT prep_request_id,
           state_id + 10
    FROM t_sample_prep_request
    WHERE state_changed > _window AND
          NOT EXISTS ( SELECT *
                       FROM t_notification_event AS TNE
                       WHERE TNE.target_id = t_sample_prep_request.prep_request_id
                             AND
                             TNE.event_type_id = (t_sample_prep_request.state_id + 10) )

    If _infoOnly Then

        SELECT COUNT(*)
        INTO _eventCount
        FROM Tmp_NewEvents;

        RAISE INFO 'Would add % % to t_notification_event', _eventCount, public.check_plural(_eventCount, 'row', 'rows');

        If _showDebug Then
            RAISE INFO '%',
                        format('%-15s %-15s',
                                'Prep Request ID',
                                'Event Type ID');

            RAISE INFO '%',
                        format('%-15s %-15s',
                                '---------------',
                                '---------------');

            FOR _eventInfo IN
                SELECT target_id As TargetID,
                       event_type_id As EventTypeID
                FROM Tmp_NewEvents
                ORDER BY target_id
            LOOP
                RAISE INFO '%',
                           format('%-15s %-15s',
                                    _eventInfo.TargetID,
                                    _eventInfo.EventTypeID);
            END LOOP;
        End If;

    Else
        ---------------------------------------------------
        -- Add new events to table
        ---------------------------------------------------

        INSERT INTO t_notification_event( event_type_id,
                                          target_id )
        SELECT Tmp_NewEvents.event_type_id,
               Tmp_NewEvents.target_id
        FROM Tmp_NewEvents
        WHERE NOT EXISTS ( SELECT TNE.target_id
                           FROM t_notification_event TNE
                           WHERE TNE.target_id = Tmp_NewEvents.target_id AND
                                 TNE.event_type_id = Tmp_NewEvents.event_type_id );

        ---------------------------------------------------
        -- Clean out batch events older than window
        ---------------------------------------------------

        DELETE FROM t_notification_event
        WHERE event_type_id BETWEEN 11 AND 19 AND
              entered < _window;

    End If;

    DROP TABLE Tmp_NewEvents;
END
$$;

COMMENT ON PROCEDURE public.make_notification_sample_prep_request_events IS 'MakeNotificationSamplePrepRequestEvents';
