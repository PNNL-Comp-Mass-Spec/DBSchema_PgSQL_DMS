--
CREATE OR REPLACE PROCEDURE public.make_notification_dataset_events
(
    _infoOnly boolean = false,
    _showDebug boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds dataset notification events to notification event table
**
**  Arguments:
**    _infoOnly     When true, show the number of notification events that would be added
**    _showDebug    When _infoOnly is true, if _showDebug is true, show details on the events that would be added
**
**  Auth:   grk
**  Date:   04/02/2010 grk - Initial version
**          04/02/2010 mem - Updated the 'Not Released' check to cover Dataset Rating -9 to 1
**                         - Now also looking for 'Released' datasets
**          11/03/2016 mem - Fix bug that was failing to remove events of type 20 (Dataset Not Released) from T_Notification_Event
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _eventCount int := 0;
    _window timestamp;
    _now timestamp;
    _past timestamp;
    _future timestamp;
    _eventTypeID int;
    _eventInfo record;
BEGIN

    _infoOnly := Coalesce(_infoOnly, false);
    _showDebug := Coalesce(_showDebug, false);

    ---------------------------------------------------
    -- Window for dataset activity
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
    );

    ---------------------------------------------------
    -- Look for Datasets that were not released, are corrupt/bad, or are marked for 'Rerun'
    ---------------------------------------------------

    _eventTypeID := 20; -- 'Dataset Not Released'

    INSERT INTO Tmp_NewEvents
    SELECT t_dataset.dataset_id,
           _eventTypeID
    FROM t_dataset
    WHERE t_dataset.dataset_rating_id BETWEEN -9 AND 1 AND
          t_dataset.created BETWEEN _window AND _now AND
          NOT EXISTS ( SELECT *
                       FROM t_notification_event AS TNE
                       WHERE TNE.target_id = t_dataset.dataset_id AND
                             TNE.event_type_id = _eventTypeID );

    ---------------------------------------------------
    -- Look for Datasets that are released
    ---------------------------------------------------

    _eventTypeID := 21; -- 'Dataset Released'

    INSERT INTO Tmp_NewEvents( target_id,
                               event_type_id )
    SELECT t_dataset.dataset_id,
           _eventTypeID
    FROM t_dataset
    WHERE t_dataset.dataset_rating_id >= 2 AND
          t_dataset.created BETWEEN _window AND _now AND
          NOT EXISTS ( SELECT *
                       FROM t_notification_event AS TNE
                       WHERE TNE.target_id = t_dataset.dataset_id AND
                             TNE.event_type_id = _eventTypeID );

    If _infoOnly Then

        SELECT COUNT(*)
        INTO _eventCount
        FROM Tmp_NewEvents;

        RAISE INFO 'Would add % % to t_notification_event', _eventCount, public.check_plural(_eventCount, 'row', 'rows');

        If _showDebug Then
            RAISE INFO '%',
                        format('%-10s %-15s',
                                'Target ID',
                                'Event Type ID');

            RAISE INFO '%',
                        format('%-10s %-15s',
                                '----------',
                                '---------------');

            FOR _eventInfo IN
                SELECT target_id As TargetID,
                       event_type_id As EventTypeID
                FROM Tmp_NewEvents
                ORDER BY target_id
            LOOP
                RAISE INFO '%',
                           format('%-10s %-15s',
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
        WHERE event_type_id IN (20, 21) AND
              entered < _window;
    End If;

    DROP TABLE Tmp_NewEvents;
END
$$;

COMMENT ON PROCEDURE public.make_notification_dataset_events IS 'MakeNotificationDatasetEvents';
