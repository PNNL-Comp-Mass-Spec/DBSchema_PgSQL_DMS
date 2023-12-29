--
CREATE OR REPLACE PROCEDURE public.make_notification_analysis_job_request_events
(
    _infoOnly boolean = false,
    _showDebug boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Add analysis job request notification events to notification event table
**
**  Arguments:
**    _infoOnly     When true, show the number of notification events that would be added
**    _showDebug    When _infoOnly is true, if _showDebug is true, show details on the events that would be added
**
**  Auth:   grk
**  Date:   03/30/2010 grk - Initial version
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
    _jobRequestInfo record;
    _eventInfo record;
BEGIN

    _infoOnly  := Coalesce(_infoOnly, false);
    _showDebug := Coalesce(_showDebug, false);

    ---------------------------------------------------
    -- Window for analysis job activity
    ---------------------------------------------------

    _window := CURRENT_TIMESTAMP - INTERVAL '7 days'

    ---------------------------------------------------
    -- Window for batch creation date
    ---------------------------------------------------

    _threshold := CURRENT_TIMESTAMP - INTERVAL '90 days'

    ---------------------------------------------------
    -- Earlier than batch creation window
    -- (default for datasets with null start time)
    ---------------------------------------------------

    _now := CURRENT_TIMESTAMP;

    _past := make_date(2000, 1, 1);

    _future := CURRENT_TIMESTAMP + INTERVAL '3 months';

    ---------------------------------------------------
    -- Temp table for analysis job requests of interest
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_AnalysisJobRequests (
        Request_ID int,
        Total_Jobs int,
        Completed_Jobs int NULL,
        Earliest_Job_Start timestamp NULL,
        Latest_Job_Finish timestamp NULL
    );

    ---------------------------------------------------
    -- Find analysis job requests to process
    ---------------------------------------------------

    INSERT INTO Tmp_AnalysisJobRequests
    SELECT t_analysis_job_request.request_id,
           COUNT(t_analysis_job.job) AS Total_Jobs,
           SUM(CASE
                   WHEN t_analysis_job.job_state_id IN (4, 14) THEN 1
                   ELSE 0
               END) AS Completed_Jobs,
           MIN(Coalesce(t_analysis_job.start, _future)) AS Earliest_Job_Start,
           MAX(Coalesce(t_analysis_job.finish, _past)) AS Latest_Job_Finish
    FROM t_analysis_job
         INNER JOIN t_analysis_job_request
           ON t_analysis_job.request_id = t_analysis_job_request.request_id
    WHERE t_analysis_job_request.request_id > 1 AND
          t_analysis_job_request.created > _threshold
    GROUP BY t_analysis_job_request.request_id;

    If _showDebug Then
        RAISE INFO '%',
                    format('%-10s %-10s %-9s %-20s %-20s',
                            'Request ID',
                            'Total Jobs',
                            'Completed',
                            'Job Start Min',
                            'Job Start Max');

        RAISE INFO '%',
                    format('%-10s %-10s %-9s %-20s %-20s',
                            '----------',
                            '----------',
                            '---------',
                            '--------------------',
                            '--------------------');

        FOR _jobRequestInfo IN
            SELECT Request_ID As RequestID,
                   Total_Jobs As TotalJobs,
                   Completed_Jobs As CompletedJobs,
                   Earliest_Job_Start As JobStartMin,
                   Latest_Job_Finish As JobFinishMax
            FROM Tmp_AnalysisJobRequests
            ORDER BY Request_ID
        LOOP
            RAISE INFO '%',
                        format('%-10s %-10s %-9s %-20s %-20s',
                                _jobRequestInfo.RequestID,
                                _jobRequestInfo.TotalJobs,
                                _jobRequestInfo.CompletedJobs,
                                to_char(_jobRequestInfo.JobStartMin, 'yyyy-mm-dd hh12:mi AM'),
                                to_char(_jobRequestInfo.JobFinishMax, 'yyyy-mm-dd hh12:mi AM')
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
    -- 4, 'Analysis Job Request Start', 2 )
    ---------------------------------------------------

    _eventType := 4;

    INSERT INTO Tmp_NewEvents( target_id,
                               event_type_id )
    SELECT entry_id,
           _eventType
    FROM Tmp_AnalysisJobRequests
    WHERE Earliest_Job_Start BETWEEN _window AND _now AND
          NOT EXISTS ( SELECT *
                       FROM t_notification_event TNE
                       WHERE TNE.target_id = Tmp_AnalysisJobRequests.entry_id AND
                             TNE.event_type_id = _eventType );

    ---------------------------------------------------
    -- 5, 'Analysis Job Request Finish', 2 )
    ---------------------------------------------------

    _eventType := 5;

    INSERT INTO Tmp_NewEvents( target_id,
                               event_type_id )
    SELECT entry_id,
           _eventType
    FROM Tmp_AnalysisJobRequests
    WHERE Total_Jobs = Completed_Jobs AND
          Latest_Job_Finish BETWEEN _window AND _now AND
          NOT EXISTS ( SELECT *
                       FROM t_notification_event TNE
                       WHERE TNE.target_id = Tmp_AnalysisJobRequests.entry_id AND
                             TNE.event_type_id = _eventType );

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
        WHERE event_type_id IN (4, 5) AND
              entered < _window;

    End If;

    DROP TABLE Tmp_AnalysisJobRequests;
    DROP TABLE Tmp_NewEvents;
END
$$;

COMMENT ON PROCEDURE public.make_notification_analysis_job_request_events IS 'MakeNotificationAnalysisJobRequestEvents';
