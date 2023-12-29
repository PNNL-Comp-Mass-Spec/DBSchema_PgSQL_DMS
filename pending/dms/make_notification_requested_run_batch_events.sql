--
CREATE OR REPLACE PROCEDURE public.make_notification_requested_run_batch_events
(
    _infoOnly boolean = false,
    _showDebug boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Add requested run batch notification events to notification event table
**
**  Arguments:
**    _infoOnly     When true, show the number of notification events that would be added
**    _showDebug    When _infoOnly is true, if _showDebug is true, show details on the events that would be added
**
**  Auth:   grk
**  Date:   03/26/2010 grk - Initial version
**          03/30/2010 grk - Added intermediate table
**          04/01/2010 grk - Added Latest_Suspect_Dataset
**          12/15/2024 mem - Ported to PostgreSQL
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
    _batchInfo record;
    _eventInfo record;
BEGIN

    _infoOnly := Coalesce(_infoOnly, false);
    _showDebug := Coalesce(_showDebug, false);

    ---------------------------------------------------
    -- Window for requested run activity
    ---------------------------------------------------

    _window := CURRENT_TIMESTAMP - INTERVAL '7 days'

    ---------------------------------------------------
    -- Window for batch creation date
    ---------------------------------------------------

    _threshold := CURRENT_TIMESTAMP - INTERVAL '365 days'

    ---------------------------------------------------
    -- Earlier than batch creation window
    -- (default for datasets with null start time)
    ---------------------------------------------------

    _now := CURRENT_TIMESTAMP;

    _past := make_date(2000, 1, 1);

    _future := CURRENT_TIMESTAMP + INTERVAL '3 months';

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
           SUM(CASE
                   WHEN TD.Dataset_ID IS NULL THEN 0
                   ELSE 1
               END) AS Num_Datasets,
           SUM(CASE
                   WHEN TD.Acq_Time_Start IS NULL THEN 0
                   ELSE 1
               END) AS Num_Datasets_With_Start_Time,
           MIN(Coalesce(TD.Created, _future)) AS Earliest_Dataset,
           MAX(Coalesce(TD.Created, _past)) AS Latest_Dataset,
           MAX(CASE
                   WHEN TD.dataset_rating_id BETWEEN - 5 AND - 1 THEN TD.Created
                   ELSE _past
               END) AS Latest_Suspect_Dataset
    FROM t_requested_run_batches AS RRB
         INNER JOIN t_requested_run AS RR
           ON RR.batch_id = RRB.Batch_ID
         LEFT OUTER JOIN t_dataset AS TD
           ON TD.Dataset_ID = RR.DatasetID
    WHERE RRB.batch_id <> 0 AND
          RRB.created > _threshold
    GROUP BY RRB.batch_id;

    If _showDebug Then

        RAISE INFO '%',
                    format('%-10s %-12s %-12s %-20s %-20s %-20s %-20s',
                            'Batch ID',
                            'Num Requests',
                            'Num Datasets',
                            'Num With Start Time',
                            'Earliest Dataset',
                            'Latest Dataset',
                            'Latest Suspect Dataset'
                          );

        RAISE INFO '%',
                    format('%-10s %-12s %-12s %-20s %-20s %-20s %-20s',
                            '----------',
                            '------------',
                            '------------',
                            '--------------------',
                            '--------------------',
                            '--------------------',
                            '--------------------'
                          );

        FOR _batchInfo IN
            SELECT Batch_ID As BatchID,
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
                        format('%-10s %-12s %-12s %-20s %-20s %-20s %-20s',
                               _batchInfo.BatchID,
                               _batchInfo.NumRequests,
                               _batchInfo.NumDatasets,
                               _batchInfo.NumWithStartTime,
                               to_char(_batchInfo.EarliestDataset, 'yyyy-mm-dd hh12:mi AM'),
                               to_char(_batchInfo.LatestDataset, 'yyyy-mm-dd hh12:mi AM'),
                               to_char(_batchInfo.LatestSuspectDataset, 'yyyy-mm-dd hh12:mi AM')
                              );

        END LOOP;
    End If;

    ---------------------------------------------------
    -- Temp table for events to be added
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_NewEvents (
        Target_ID int,
        Event_Type int
    );

    ---------------------------------------------------
    -- Event 'Requested Run Batch Start'
    -- * Num_Datasets > 0
    -- * Earliest_Dataset within window
    -- * 'Requested Run Batch Start' event and RRB.ID not already in event table
    ---------------------------------------------------

    _eventType := 1;

    INSERT INTO Tmp_NewEvents( target_id,
                               event_type_id )
    SELECT entry_id,
           _eventType
    FROM Tmp_AnalysisJobs
    WHERE Num_Datasets > 0 AND
          Earliest_Dataset BETWEEN _window AND _now AND
          NOT EXISTS ( SELECT *
                       FROM t_notification_event TNE
                       WHERE TNE.target_id = Tmp_AnalysisJobs.entry_id
                             AND
                             TNE.event_type_id = _eventType );

    ---------------------------------------------------
    -- Event 'Requested Run Batch Finish'
    --- Num_Requests = Num_Datasets
    --- Latest_Dataset within window
    --- 'Requested Run Batch Finish' event and RRB.ID not already in event table
    ---------------------------------------------------

    _eventType := 2;

    INSERT INTO Tmp_NewEvents( target_id,
                               event_type_id )
    SELECT entry_id,
           _eventType
    FROM Tmp_AnalysisJobs
    WHERE Num_Datasets = Num_Requests AND
          Latest_Dataset BETWEEN _window AND _now AND
          NOT EXISTS ( SELECT *
                       FROM t_notification_event TNE
                       WHERE TNE.target_id = Tmp_AnalysisJobs.entry_id
                             AND
                             TNE.event_type_id = _eventType );

    ---------------------------------------------------
    -- Event 'Requested Run Batch Acq Time Ready'
    --- Num_Requests = Num_Datasets_With_Start_Time
    --- Latest_Dataset within window
    --- 'Requested Run Batch Acq Time Ready' event and RRB.ID not already in event table
    ---------------------------------------------------

    _eventType := 3;

    INSERT INTO Tmp_NewEvents( target_id,
                               event_type_id )
    SELECT entry_id,
           _eventType
    FROM Tmp_AnalysisJobs
    WHERE Num_Requests = Num_Datasets_With_Start_Time AND
          Latest_Dataset BETWEEN _window AND _now AND
          NOT EXISTS ( SELECT *
                       FROM t_notification_event TNE
                       WHERE TNE.target_id = Tmp_AnalysisJobs.entry_id AND
                             TNE.event_type_id = _eventType );

    If _infoOnly Then

        SELECT COUNT(*)
        INTO _eventCount
        FROM Tmp_NewEvents;

        RAISE INFO 'Would add % % to t_notification_event', _eventCount, public.check_plural(_eventCount, 'row', 'rows');

        If _showDebug Then
            RAISE INFO '%',
                        format('%-10s %-15s',
                                'Batch ID',
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
        WHERE event_type_id IN (1, 2, 3) AND
              entered < _window;
    End If;

    DROP TABLE Tmp_AnalysisJobs;
    DROP TABLE Tmp_NewEvents;
END
$$;

COMMENT ON PROCEDURE public.make_notification_requested_run_batch_events IS 'MakeNotificationRequestedRunBatchEvents';
