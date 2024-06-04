--
-- Name: make_notification_analysis_job_request_events(boolean, boolean, boolean, timestamp without time zone); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.make_notification_analysis_job_request_events(IN _infoonly boolean DEFAULT false, IN _showdebug boolean DEFAULT false, IN _deleteoldevents boolean DEFAULT true, IN _timestampoverride timestamp without time zone DEFAULT NULL::timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add analysis job request notification events to the notification event table
**
**  Arguments:
**    _infoOnly             When true, show the number of notification events that would be added
**    _showDebug            When _infoOnly is true, if _showDebug is true, show details on the events that would be added
**    _deleteOldEvents      When true (the default), delete dataset 'released' or 'not released' notification events that are more than 7 days old
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
    _threshold timestamp;
    _now timestamp;
    _past timestamp;
    _future timestamp;
    _eventType int;
    _formatSpecifier text;
    _jobRequestInfo record;
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
    -- Window for job start or finish
    ---------------------------------------------------

    _window := _now - INTERVAL '7 days';

    ---------------------------------------------------
    -- Window for analysis job request date
    ---------------------------------------------------

    _threshold := _now - INTERVAL '90 days';

    _past := make_date(2000, 1, 1);

    _future := _now + INTERVAL '3 months';

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
    SELECT AJR.request_id,
           COUNT(AJ.job) AS Total_Jobs,
           SUM(CASE WHEN AJ.job_state_id IN (4, 14) THEN 1
                    ELSE 0
               END) AS Completed_Jobs,
           MIN(Coalesce(AJ.start, _future)) AS Earliest_Job_Start,
           MAX(Coalesce(AJ.finish, _past)) AS Latest_Job_Finish
    FROM t_analysis_job AJ
         INNER JOIN t_analysis_job_request AJR
           ON AJ.request_id = AJR.request_id
    WHERE AJR.request_id > 1 AND
          AJR.created > _threshold
    GROUP BY AJR.request_id;

    If _showDebug Then
        RAISE INFO '';

        _formatSpecifier := '%-10s %-10s %-9s %-20s %-20s';

        RAISE INFO '%',
                    format(_formatSpecifier,
                           'Request ID',
                           'Total Jobs',
                           'Completed',
                           'Job Start Min',
                           'Job Start Max');

        RAISE INFO '%',
                    format(_formatSpecifier,
                           '----------',
                           '----------',
                           '---------',
                           '--------------------',
                           '--------------------');

        FOR _jobRequestInfo IN
            SELECT Request_ID         AS RequestID,
                   Total_Jobs         AS TotalJobs,
                   Completed_Jobs     AS CompletedJobs,
                   Earliest_Job_Start AS JobStartMin,
                   Latest_Job_Finish  AS JobFinishMax
            FROM Tmp_AnalysisJobRequests
            ORDER BY Request_ID
        LOOP
            RAISE INFO '%',
                        format(_formatSpecifier,
                               _jobRequestInfo.RequestID,
                               _jobRequestInfo.TotalJobs,
                               _jobRequestInfo.CompletedJobs,
                               to_char(_jobRequestInfo.JobStartMin,  'yyyy-mm-dd hh12:mi AM'),
                               to_char(_jobRequestInfo.JobFinishMax, 'yyyy-mm-dd hh12:mi AM')
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
    -- Event type 4, is 'Analysis Job Request Start'
    ---------------------------------------------------

    _eventType := 4;

    INSERT INTO Tmp_NewEvents (target_id, event_type_id)
    SELECT Request_ID,
           _eventType
    FROM Tmp_AnalysisJobRequests
    WHERE Earliest_Job_Start BETWEEN _window AND _now AND
          NOT EXISTS (SELECT 1
                      FROM t_notification_event TNE
                      WHERE TNE.target_id = Tmp_AnalysisJobRequests.Request_ID AND
                            TNE.event_type_id = _eventType);

    ---------------------------------------------------
    -- Event type 5, is 'Analysis Job Request Finish'
    ---------------------------------------------------

    _eventType := 5;

    INSERT INTO Tmp_NewEvents (target_id, event_type_id)
    SELECT Request_ID,
           _eventType
    FROM Tmp_AnalysisJobRequests
    WHERE Total_Jobs = Completed_Jobs AND
          Latest_Job_Finish BETWEEN _window AND _now AND
          NOT EXISTS (SELECT 1
                      FROM t_notification_event TNE
                      WHERE TNE.target_id = Tmp_AnalysisJobRequests.Request_ID AND
                            TNE.event_type_id = _eventType);

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
            -- Clean out analysis job request events older than window
            ---------------------------------------------------

            DELETE FROM t_notification_event
            WHERE event_type_id IN (4, 5) AND
                  entered < _window;

        End If;
    End If;

    DROP TABLE Tmp_AnalysisJobRequests;
    DROP TABLE Tmp_NewEvents;
END
$$;


ALTER PROCEDURE public.make_notification_analysis_job_request_events(IN _infoonly boolean, IN _showdebug boolean, IN _deleteoldevents boolean, IN _timestampoverride timestamp without time zone) OWNER TO d3l243;

--
-- Name: PROCEDURE make_notification_analysis_job_request_events(IN _infoonly boolean, IN _showdebug boolean, IN _deleteoldevents boolean, IN _timestampoverride timestamp without time zone); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.make_notification_analysis_job_request_events(IN _infoonly boolean, IN _showdebug boolean, IN _deleteoldevents boolean, IN _timestampoverride timestamp without time zone) IS 'MakeNotificationAnalysisJobRequestEvents';

