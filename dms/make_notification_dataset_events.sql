--
-- Name: make_notification_dataset_events(boolean, boolean, boolean, timestamp without time zone); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.make_notification_dataset_events(IN _infoonly boolean DEFAULT false, IN _showdebug boolean DEFAULT false, IN _deleteoldevents boolean DEFAULT true, IN _timestampoverride timestamp without time zone DEFAULT NULL::timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add dataset notification events to the notification event table
**
**  Arguments:
**    _infoOnly             When true, show the number of notification events that would be added
**    _showDebug            When _infoOnly is true, if _showDebug is true, show details on the events that would be added
**    _deleteOldEvents      When true (the default), delete dataset 'released' or 'not released' notification events that are more than 7 days old
**    _timestampOverride    Optional, specific timestamp to use for finding events when _infoOnly is true; when _infoOnly is false, this procedure uses the current timestamp
**
**  Auth:   grk
**  Date:   04/02/2010 grk - Initial version
**          04/02/2010 mem - Updated the 'Not Released' check to cover Dataset Rating -9 to 1
**                         - Now also looking for 'Released' datasets
**          11/03/2016 mem - Fix bug that was failing to remove events of type 20 (Dataset Not Released) from T_Notification_Event
**          02/14/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _eventCount int := 0;
    _window timestamp;
    _now timestamp;
    _past timestamp;
    _future timestamp;
    _eventTypeID int;
    _formatSpecifier text;
    _eventInfo record;
BEGIN

    _infoOnly        := Coalesce(_infoOnly, false);
    _showDebug       := Coalesce(_showDebug, false);
    _deleteOldEvents := Coalesce(_deleteOldEvents, true);

    If _infoOnly Then
        _now := Coalesce(_timestampOverride, CURRENT_TIMESTAMP);
    Else
        If Not _timestampOverride Is Null Then
            RAISE INFO 'Ignoring _timestampOverride since _infoOnly is false';
        End If;

        _now := CURRENT_TIMESTAMP;
    End If;

    ---------------------------------------------------
    -- Window for dataset activity
    ---------------------------------------------------

    _window := _now - INTERVAL '7 days';

    ---------------------------------------------------
    -- Temp table for events to be added
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_NewEvents (
        Target_ID int,
        Event_Type_ID int
    );

    ---------------------------------------------------
    -- Look for datasets that are not released, are corrupt/bad, or are marked for 'Rerun'
    ---------------------------------------------------

    _eventTypeID := 20; -- 'Dataset Not Released'

    INSERT INTO Tmp_NewEvents
    SELECT t_dataset.dataset_id,
           _eventTypeID
    FROM t_dataset
    WHERE t_dataset.dataset_rating_id BETWEEN -9 AND 1 AND
          t_dataset.created BETWEEN _window AND _now AND
          NOT EXISTS (SELECT 1
                      FROM t_notification_event AS TNE
                      WHERE TNE.target_id = t_dataset.dataset_id AND
                            TNE.event_type_id = _eventTypeID);

    ---------------------------------------------------
    -- Look for datasets that are released
    ---------------------------------------------------

    _eventTypeID := 21; -- 'Dataset Released'

    INSERT INTO Tmp_NewEvents (target_id, event_type_id)
    SELECT t_dataset.dataset_id,
           _eventTypeID
    FROM t_dataset
    WHERE t_dataset.dataset_rating_id >= 2 AND
          t_dataset.created BETWEEN _window AND _now AND
          NOT EXISTS (SELECT 1
                      FROM t_notification_event AS TNE
                      WHERE TNE.target_id = t_dataset.dataset_id AND
                            TNE.event_type_id = _eventTypeID);

    If _infoOnly Then

        SELECT COUNT(*)
        INTO _eventCount
        FROM Tmp_NewEvents;

        RAISE INFO '';
        RAISE INFO 'Would add % % to t_notification_event', _eventCount, public.check_plural(_eventCount, 'row', 'rows');

        If _showDebug Then
            RAISE INFO '';

            _formatSpecifier := '%-10s %-15s';

            RAISE INFO '%',
                        format(_formatSpecifier,
                               'Target ID',
                               'Event Type ID');

            RAISE INFO '%',
                        format(_formatSpecifier,
                               '----------',
                               '---------------');

            FOR _eventInfo IN
                SELECT target_id AS TargetID,
                       event_type_id AS EventTypeID
                FROM Tmp_NewEvents
                ORDER BY target_id
            LOOP
                RAISE INFO '%',
                           format(_formatSpecifier,
                                  _eventInfo.TargetID,
                                  _eventInfo.EventTypeID);

            END LOOP;
        End If;

    Else
        ---------------------------------------------------
        -- Add new events to table
        ---------------------------------------------------

        INSERT INTO t_notification_event (event_type_id, target_id)
        SELECT Tmp_NewEvents.event_type_id,
               Tmp_NewEvents.target_id
        FROM Tmp_NewEvents
        WHERE NOT EXISTS (SELECT TNE.target_id
                          FROM t_notification_event TNE
                          WHERE TNE.target_id = Tmp_NewEvents.target_id AND
                                TNE.event_type_id = Tmp_NewEvents.event_type_id);

        If _deleteOldEvents Then

            ---------------------------------------------------
            -- Clean out dataset 'released' or 'not released' events older than window
            ---------------------------------------------------

            DELETE FROM t_notification_event
            WHERE event_type_id IN (20, 21) AND
                  entered < _window;

        End If;
    End If;

    DROP TABLE Tmp_NewEvents;
END
$$;


ALTER PROCEDURE public.make_notification_dataset_events(IN _infoonly boolean, IN _showdebug boolean, IN _deleteoldevents boolean, IN _timestampoverride timestamp without time zone) OWNER TO d3l243;

--
-- Name: PROCEDURE make_notification_dataset_events(IN _infoonly boolean, IN _showdebug boolean, IN _deleteoldevents boolean, IN _timestampoverride timestamp without time zone); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.make_notification_dataset_events(IN _infoonly boolean, IN _showdebug boolean, IN _deleteoldevents boolean, IN _timestampoverride timestamp without time zone) IS 'MakeNotificationDatasetEvents';

