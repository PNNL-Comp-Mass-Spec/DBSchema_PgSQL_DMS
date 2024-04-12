--
-- Name: make_notification_requested_run_batch_events(boolean, boolean, boolean, timestamp without time zone); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.make_notification_requested_run_batch_events(IN _infoonly boolean DEFAULT false, IN _showdebug boolean DEFAULT false, IN _deleteoldevents boolean DEFAULT true, IN _timestampoverride timestamp without time zone DEFAULT NULL::timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add requested run batch notification events to the notification event table
**
**  Arguments:
**    _infoOnly             When true, show the number of notification events that would be added
**    _showDebug            When _infoOnly is true, if _showDebug is true, show details on the events that would be added
**    _deleteOldEvents      When true (the default), delete requested run batch notification events that are more than 7 days old
**    _timestampOverride    Optional, specific timestamp to use for finding events when _infoOnly is true; when _infoOnly is false, this procedure uses the current timestamp
**
**  Auth:   grk
**  Date:   03/26/2010 grk - Initial version
**          03/30/2010 grk - Added intermediate table
**          04/01/2010 grk - Added Latest_Suspect_Dataset
**          02/14/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _eventCount int := 0;
    _window timestamp;
    _threshold timestamp;
    _now timestamp;
    _past timestamp;
    _future timestamp;
    _eventType int;
    _formatSpecifier text;
    _batchInfo record;
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
    -- Window for requested run activity
    ---------------------------------------------------

    _window := _now - INTERVAL '7 days';

    ---------------------------------------------------
    -- Window for batch creation date
    ---------------------------------------------------

    _threshold := _now - INTERVAL '365 days';

    _past := make_date(2000, 1, 1);

    _future := _now + INTERVAL '3 months';

    ---------------------------------------------------
    -- Temp table for batches of interest
    -- (batches created within epoc with datasets present)
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_RequestedRunBatches (
        Batch_ID int,
        Num_Requests int,
        Num_Datasets int NULL,
        Num_Datasets_With_Start_Time int NULL,
        Earliest_Dataset timestamp NULL,
        Latest_Dataset timestamp NULL,
        Latest_Suspect_Dataset timestamp NULL
    );

    ---------------------------------------------------
    -- Find requested run batches to process
    ---------------------------------------------------

    INSERT INTO Tmp_RequestedRunBatches
    SELECT RRB.Batch_ID,
           COUNT(RR.request_id) AS Num_Requests,
           SUM(CASE WHEN TD.Dataset_ID IS NULL THEN 0
                    ELSE 1
               END) AS Num_Datasets,
           SUM(CASE WHEN TD.Acq_Time_Start IS NULL THEN 0
                    ELSE 1
               END) AS Num_Datasets_With_Start_Time,
           MIN(Coalesce(TD.Created, _future)) AS Earliest_Dataset,
           MAX(Coalesce(TD.Created, _past)) AS Latest_Dataset,
           MAX(CASE WHEN TD.dataset_rating_id BETWEEN - 5 AND - 1 THEN TD.Created
                    ELSE _past
               END) AS Latest_Suspect_Dataset
    FROM t_requested_run_batches AS RRB
         INNER JOIN t_requested_run AS RR
           ON RR.batch_id = RRB.Batch_ID
         LEFT OUTER JOIN t_dataset AS TD
           ON TD.Dataset_ID = RR.Dataset_ID
    WHERE RRB.batch_id <> 0 AND
          RRB.created > _threshold
    GROUP BY RRB.batch_id;

    If _showDebug Then
        RAISE INFO '';

        _formatSpecifier := '%-10s %-12s %-12s %-20s %-20s %-20s %-22s';

        RAISE INFO '%',
                    format(_formatSpecifier,
                           'Batch ID',
                           'Num Requests',
                           'Num Datasets',
                           'Num With Start Time',
                           'Earliest Dataset',
                           'Latest Dataset',
                           'Latest Suspect Dataset'
                          );

        RAISE INFO '%',
                    format(_formatSpecifier,
                           '----------',
                           '------------',
                           '------------',
                           '--------------------',
                           '--------------------',
                           '--------------------',
                           '----------------------'
                          );

        FOR _batchInfo IN
            SELECT Batch_ID AS BatchID,
                   Num_Requests AS NumRequests,
                   Num_Datasets AS NumDatasets,
                   Num_Datasets_With_Start_Time AS NumWithStartTime,
                   Earliest_Dataset AS EarliestDataset,
                   Latest_Dataset AS LatestDataset,
                   Latest_Suspect_Dataset AS LatestSuspectDataset
            FROM Tmp_RequestedRunBatches
            ORDER BY Batch_ID
        LOOP
            RAISE INFO '%',
                        format(_formatSpecifier,
                               _batchInfo.BatchID,
                               _batchInfo.NumRequests,
                               _batchInfo.NumDatasets,
                               _batchInfo.NumWithStartTime,
                               to_char(_batchInfo.EarliestDataset,      'yyyy-mm-dd hh12:mi AM'),
                               to_char(_batchInfo.LatestDataset,        'yyyy-mm-dd hh12:mi AM'),
                               to_char(_batchInfo.LatestSuspectDataset, 'yyyy-mm-dd hh12:mi AM')
                              );

        END LOOP;
    End If;

    ---------------------------------------------------
    -- Temp table for events to be added
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_NewEvents (
        Target_ID int,
        Event_Type_ID int
    );

    ---------------------------------------------------
    -- Event 'Requested Run Batch Start'
    --   Num_Datasets > 0
    --   Earliest_Dataset within window
    --   'Requested Run Batch Start' event and RRB.Batch_ID not already in event table
    ---------------------------------------------------

    _eventType := 1;

    INSERT INTO Tmp_NewEvents (target_id, event_type_id)
    SELECT Batch_ID,
           _eventType
    FROM Tmp_RequestedRunBatches
    WHERE Num_Datasets > 0 AND
          Earliest_Dataset BETWEEN _window AND _now AND
          NOT EXISTS ( SELECT 1
                       FROM t_notification_event TNE
                       WHERE TNE.target_id = Tmp_RequestedRunBatches.Batch_ID
                             AND
                             TNE.event_type_id = _eventType );

    ---------------------------------------------------
    -- Event 'Requested Run Batch Finish'
    --   Num_Requests = Num_Datasets
    --   Latest_Dataset within window
    --   'Requested Run Batch Finish' event and RRB.Batch_ID not already in event table
    ---------------------------------------------------

    _eventType := 2;

    INSERT INTO Tmp_NewEvents (target_id, event_type_id)
    SELECT Batch_ID,
           _eventType
    FROM Tmp_RequestedRunBatches
    WHERE Num_Datasets = Num_Requests AND
          Latest_Dataset BETWEEN _window AND _now AND
          NOT EXISTS ( SELECT 1
                       FROM t_notification_event TNE
                       WHERE TNE.target_id = Tmp_RequestedRunBatches.Batch_ID
                             AND
                             TNE.event_type_id = _eventType );

    ---------------------------------------------------
    -- Event 'Requested Run Batch Acq Time Ready'
    --   Num_Requests = Num_Datasets_With_Start_Time
    --   Latest_Dataset within window
    --   'Requested Run Batch Acq Time Ready' event and RRB.Batch_ID not already in event table
    ---------------------------------------------------

    _eventType := 3;

    INSERT INTO Tmp_NewEvents (target_id, event_type_id)
    SELECT Batch_ID,
           _eventType
    FROM Tmp_RequestedRunBatches
    WHERE Num_Requests = Num_Datasets_With_Start_Time AND
          Latest_Dataset BETWEEN _window AND _now AND
          NOT EXISTS ( SELECT 1
                       FROM t_notification_event TNE
                       WHERE TNE.target_id = Tmp_RequestedRunBatches.Batch_ID AND
                             TNE.event_type_id = _eventType );

    If _infoOnly Then

        SELECT COUNT(*)
        INTO _eventCount
        FROM Tmp_NewEvents;

        If _showDebug Then
            RAISE INFO '';
        End If;

        RAISE INFO 'Would add % % to t_notification_event', _eventCount, public.check_plural(_eventCount, 'row', 'rows');

        If _showDebug Then
            RAISE INFO '';

            _formatSpecifier := '%-10s %-15s';

            RAISE INFO '%',
                        format(_formatSpecifier,
                               'Batch ID',
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
        WHERE NOT EXISTS ( SELECT TNE.target_id
                           FROM t_notification_event TNE
                           WHERE TNE.target_id = Tmp_NewEvents.target_id AND
                                 TNE.event_type_id = Tmp_NewEvents.event_type_id );

        If _deleteOldEvents Then

            ---------------------------------------------------
            -- Clean out requested run batch events older than window
            ---------------------------------------------------

            DELETE FROM t_notification_event
            WHERE event_type_id IN (1, 2, 3) AND
                  entered < _window;

        End If;

    End If;

    DROP TABLE Tmp_RequestedRunBatches;
    DROP TABLE Tmp_NewEvents;
END
$$;


ALTER PROCEDURE public.make_notification_requested_run_batch_events(IN _infoonly boolean, IN _showdebug boolean, IN _deleteoldevents boolean, IN _timestampoverride timestamp without time zone) OWNER TO d3l243;

--
-- Name: PROCEDURE make_notification_requested_run_batch_events(IN _infoonly boolean, IN _showdebug boolean, IN _deleteoldevents boolean, IN _timestampoverride timestamp without time zone); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.make_notification_requested_run_batch_events(IN _infoonly boolean, IN _showdebug boolean, IN _deleteoldevents boolean, IN _timestampoverride timestamp without time zone) IS 'MakeNotificationRequestedRunBatchEvents';

