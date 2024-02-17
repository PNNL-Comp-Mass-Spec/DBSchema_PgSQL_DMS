--
-- Name: make_notification_sample_prep_request_events(boolean, boolean, boolean, timestamp without time zone); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.make_notification_sample_prep_request_events(IN _infoonly boolean DEFAULT false, IN _showdebug boolean DEFAULT false, IN _deleteoldevents boolean DEFAULT true, IN _timestampoverride timestamp without time zone DEFAULT NULL::timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add sample prep request notification events to the notification event table
**
**  Arguments:
**    _infoOnly             When true, show the number of notification events that would be added
**    _showDebug            When _infoOnly is true, if _showDebug is true, show details on the events that would be added
**    _deleteOldEvents      When true (the default), delete sample prep request notification events that are more than 7 days old
**    _timestampOverride    Optional, specific timestamp to use for finding events when _infoOnly is true; when _infoOnly is false, this procedure uses the current timestamp
**
**  Auth:   grk
**  Date:   03/30/2010 grk - Initial version
**          02/14/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _eventCount int := 0;
    _window timestamp;
    _now timestamp;
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
    -- Window for sample prep request activity
    ---------------------------------------------------

    _window := _now - INTERVAL '7 days';

    ---------------------------------------------------
    -- Temp table for events to be added
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_NewEvents (
        Target_ID int,
        Event_Type_ID int
    );

    INSERT INTO Tmp_NewEvents
    SELECT prep_request_id,
           state_id + 10
    FROM t_sample_prep_request
    WHERE state_changed > _window AND
          NOT EXISTS ( SELECT 1
                       FROM t_notification_event AS TNE
                       WHERE TNE.target_id = t_sample_prep_request.prep_request_id AND
                             TNE.event_type_id = (t_sample_prep_request.state_id + 10) );

    If _infoOnly Then

        SELECT COUNT(*)
        INTO _eventCount
        FROM Tmp_NewEvents;

        RAISE INFO '';

        RAISE INFO 'Would add % % to t_notification_event', _eventCount, public.check_plural(_eventCount, 'row', 'rows');

        If _showDebug Then
            RAISE INFO '';

            _formatSpecifier := '%-15s %-15s';

            RAISE INFO '%',
                        format(_formatSpecifier,
                               'Prep Request ID',
                               'Event Type ID');

            RAISE INFO '%',
                        format(_formatSpecifier,
                               '---------------',
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

        INSERT INTO t_notification_event( event_type_id,
                                          target_id )
        SELECT Tmp_NewEvents.event_type_id,
               Tmp_NewEvents.target_id
        FROM Tmp_NewEvents
        WHERE NOT EXISTS ( SELECT TNE.target_id
                           FROM t_notification_event TNE
                           WHERE TNE.target_id = Tmp_NewEvents.target_id AND
                                 TNE.event_type_id = Tmp_NewEvents.event_type_id );

        If _deleteOldEvents Then

            ---------------------------------------------------
            -- Clean out sample prep request events older than window
            ---------------------------------------------------

            DELETE FROM t_notification_event
            WHERE event_type_id BETWEEN 11 AND 19 AND
                  entered < _window;

        End If;

    End If;

    DROP TABLE Tmp_NewEvents;
END
$$;


ALTER PROCEDURE public.make_notification_sample_prep_request_events(IN _infoonly boolean, IN _showdebug boolean, IN _deleteoldevents boolean, IN _timestampoverride timestamp without time zone) OWNER TO d3l243;

--
-- Name: PROCEDURE make_notification_sample_prep_request_events(IN _infoonly boolean, IN _showdebug boolean, IN _deleteoldevents boolean, IN _timestampoverride timestamp without time zone); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.make_notification_sample_prep_request_events(IN _infoonly boolean, IN _showdebug boolean, IN _deleteoldevents boolean, IN _timestampoverride timestamp without time zone) IS 'MakeNotificationSamplePrepRequestEvents';

