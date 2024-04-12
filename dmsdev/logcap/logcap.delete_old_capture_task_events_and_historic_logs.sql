--
-- Name: delete_old_capture_task_events_and_historic_logs(boolean, integer, text, text); Type: PROCEDURE; Schema: logcap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE logcap.delete_old_capture_task_events_and_historic_logs(IN _infoonly boolean DEFAULT false, IN _yearfilter integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete entries over 2 years old in logcap.t_task_events, logcap.t_task_step_events,
**      logcap.t_task_step_processing_log, and logcap.t_log_entries
**
**      However, keep two weeks of events per year for historic reference purposes
**      (retain the first week of February and the first week of August)
**
**  Arguments:
**    _infoOnly         When true, preview a sampling of the events that would be deleted
**    _yearFilter       If 1970 or larger, only delete events in the given year
**    _message          Status message
**    _returnCode       Return code
**
**  Date:   06/08/2022 mem - Initial version
**          08/26/2022 mem - Use new column name in T_Log_Entries
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          02/27/2024 mem - Ported to PostgreSQL
**          02/28/2024 mem - Create temporary tables, not permanent tables
**
*****************************************************/
DECLARE
    _dateThreshold timestamp;
    _thresholdDescription text;

    _matchCount int;
    _eventsToDelete int;
    _eventIdMin int;
    _eventIdMax int;

    _logEntriesToDelete int;
    _entryIdMin int;
    _entryIdMax int;

    _jobEventsMessage text = '';
    _jobStepEventsMessage text = '';
    _jobStepProcessingLogMessage text = '';
    _historicLogMessage text = '';

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _infoOnly   := Coalesce(_infoOnly, true);
        _yearFilter := Coalesce(_yearFilter, 0);

        ---------------------------------------------------
        -- Create temp tables to hold the IDs of the items to delete
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_TaskEventIDs (
            Event_ID int NOT NULL,
            Entered  timestamp NOT NULL,
            PRIMARY KEY ( Event_ID )
        );

        CREATE TEMP TABLE Tmp_TaskStepEventIDs (
            Event_ID int NOT NULL,
            Entered  timestamp NOT NULL,
            PRIMARY KEY ( Event_ID )
        );

        CREATE TEMP TABLE Tmp_ProcessingLogEventIDs (
            Event_ID int NOT NULL,
            Entered  timestamp NOT NULL,
            PRIMARY KEY ( Event_ID )
        );

        CREATE TEMP TABLE Tmp_HistoricLogIDs (
            Entry_ID int NOT NULL,
            Entered  timestamp NOT NULL,
            PRIMARY KEY ( Entry_ID, Entered )
        );

        CREATE TEMP TABLE Tmp_EventsToDelete (
            Target_Table citext Not Null,
            Event_ID int NOT NULL,
            Job int NULL,
            Step int NULL,
            Target_State int NULL,
            Prev_Target_State int NULL,
            Processor citext Null,
            Entered timestamp NULL,
            PRIMARY KEY (Target_Table, Event_ID)
        );

        CREATE TEMP TABLE Tmp_LogEntriesToDelete (
            Entry_ID int NOT NULL,
            Posted_By citext NULL,
            Entered timestamp NOT NULL,
            Type citext NULL,
            Message citext NULL
        );

        ---------------------------------------------------
        -- Define the date threshold by subtracting two years from January 1 of this year
        ---------------------------------------------------

        _dateThreshold := make_date(date_part('year', CURRENT_TIMESTAMP)::int, 1, 1) - Interval '2 years';

        _thresholdDescription := format('using date threshold %s', Left(public.timestamp_text(_dateThreshold), 10));

        If _yearFilter >= 1970 Then
            _thresholdDescription := format('%s and year filter %s', _thresholdDescription, _yearFilter);
        End If;

        ---------------------------------------------------
        -- Find items to delete in t_task_events
        ---------------------------------------------------

        INSERT INTO Tmp_TaskEventIDs (Event_ID, Entered)
        SELECT event_id, entered
        FROM logcap.t_task_events
        WHERE entered < _dateThreshold AND
              NOT (date_part('month', entered)::int IN (2,8) And date_part('day', entered)::int BETWEEN 1 AND 7) AND
              (_yearFilter < 1970 Or date_part('year', entered)::int = _yearFilter);
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        _eventsToDelete := _matchCount;

        If _eventsToDelete = 0 Then
            _jobEventsMessage := format('No job event entries were found %s', _thresholdDescription);
        Else
            SELECT COUNT(Event_ID),
                   MIN(Event_ID),
                   MAX(Event_ID)
            INTO _eventsToDelete, _eventIdMin, _eventIdMax
            FROM Tmp_TaskEventIDs;

            ---------------------------------------------------
            -- Delete the old job events (preview if _infoOnly is true)
            ---------------------------------------------------

            If _infoOnly Then
                -- Cache the 10 oldest job events to delete
                INSERT INTO Tmp_EventsToDelete (Target_Table, Event_ID, Job, Step, Target_State, Prev_Target_State, Processor, Entered)
                SELECT 'T_Task_Events', T.Event_ID, T.Job, Null As Step, T.Target_State, T.Prev_Target_State, Null As Processor, T.Entered
                FROM Tmp_TaskEventIDs S
                     INNER JOIN logcap.t_task_events T
                       ON S.event_id = T.Event_ID
                ORDER BY S.event_id
                LIMIT 10;

                -- Append the 10 newest job events to delete
                INSERT INTO Tmp_EventsToDelete (Target_Table, Event_ID, Job, Step, Target_State, Prev_Target_State, Processor, Entered)
                SELECT 'T_Task_Events', T.Event_ID,  T.Job, Null As Step, T.Target_State, T.Prev_Target_State, Null As Processor, T.Entered
                FROM ( SELECT Event_ID
                       FROM Tmp_TaskEventIDs
                       ORDER BY Event_ID DESC
                       LIMIT 10
                     ) S
                     INNER JOIN logcap.t_task_events T
                       ON S.event_id = T.Event_ID
                ORDER BY S.event_id
                LIMIT 10;

            Else
                DELETE FROM logcap.t_task_events Target
                WHERE EXISTS (SELECT 1
                              FROM Tmp_TaskEventIDs Src
                              WHERE Target.event_id = Src.Event_ID);
            End If;

            If _infoOnly Then
                _jobEventsMessage := 'Would delete';
            Else
                _jobEventsMessage := 'Deleted';
            End If;

            _jobEventsMessage := format('%s %s old entries from logcap.t_task_events %s; event ID range %s to %s',
                                        _jobEventsMessage, _eventsToDelete, _thresholdDescription, _eventIdMin, _eventIdMax);

            If Not _infoOnly Then
                CALL post_log_entry ('Normal', _jobEventsMessage, 'delete_old_capture_task_events_and_historic_logs', _targetSchema => 'logcap');
            End If;
        End If;

        ---------------------------------------------------
        -- Find items to delete in logcap.t_task_step_events
        ---------------------------------------------------

        INSERT INTO Tmp_TaskStepEventIDs (Event_ID, Entered)
        SELECT Event_ID, Entered
        FROM logcap.t_task_step_events
        WHERE entered < _dateThreshold AND
              NOT (date_part('month', entered)::int IN (2,8) And date_part('day', entered)::int BETWEEN 1 AND 7) AND
              (_yearFilter < 1970 Or date_part('year', entered)::int = _yearFilter);
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        _eventsToDelete := _matchCount;

        If _eventsToDelete = 0 Then
            _jobStepEventsMessage := format('No job step event entries were found %s', _thresholdDescription);
        Else
            SELECT COUNT(Event_ID),
                   MIN(Event_ID),
                   MAX(Event_ID)
            INTO _eventsToDelete, _eventIdMin, _eventIdMax
            FROM Tmp_TaskStepEventIDs;

            ---------------------------------------------------
            -- Delete the old job step events (preview if _infoOnly is true)
            ---------------------------------------------------

            If _infoOnly Then
                INSERT INTO Tmp_EventsToDelete (Target_Table, Event_ID, Job, Step, Target_State, Prev_Target_State, Processor, Entered)
                SELECT 'T_Task_Step_Events', T.Event_ID, T.Job, T.Step, T.Target_State, T.Prev_Target_State, Null As Processor, T.Entered
                FROM Tmp_TaskStepEventIDs S
                     INNER JOIN logcap.t_task_step_events T
                       ON S.Event_ID = T.Event_ID
                ORDER BY S.Event_ID
                LIMIT 10;

                INSERT INTO Tmp_EventsToDelete (Target_Table, Event_ID, Job, Step, Target_State, Prev_Target_State, Processor, Entered)
                SELECT 'T_Task_Step_Events', T.Event_ID, T.Job, T.Step, T.Target_State, T.Prev_Target_State, Null As Processor, T.Entered
                FROM ( SELECT Event_ID
                       FROM Tmp_TaskStepEventIDs
                       ORDER BY Event_ID DESC
                       LIMIT 10
                     ) S
                     INNER JOIN logcap.t_task_step_events T
                       ON S.Event_ID = T.Event_ID
                ORDER BY T.Event_ID
                LIMIT 10;

            Else
                DELETE FROM logcap.t_task_step_events Target
                WHERE EXISTS (SELECT 1
                              FROM Tmp_TaskStepEventIDs Src
                              WHERE target.event_id = Src.Event_ID);

            End If;

            If _infoOnly Then
                _jobStepEventsMessage := 'Would delete';
            Else
                _jobStepEventsMessage := 'Deleted';
            End If;

             _jobStepEventsMessage := format('%s %s old entries from logcap.t_task_step_events %s; event ID range %s to %s',
                                             _jobStepEventsMessage, _eventsToDelete, _thresholdDescription, _eventIdMin, _eventIdMax);

            If Not _infoOnly Then
                CALL post_log_entry ('Normal', _jobStepEventsMessage, 'delete_old_capture_task_events_and_historic_logs', _targetSchema => 'logcap');
            End If;
        End If;

        ---------------------------------------------------
        -- Find items to delete in logcap.t_task_step_processing_log
        ---------------------------------------------------

        INSERT INTO Tmp_ProcessingLogEventIDs (Event_ID, Entered)
        SELECT Event_ID, Entered
        FROM logcap.t_task_step_processing_log
        WHERE entered < _dateThreshold AND
              NOT (date_part('month', entered)::int IN (2,8) And date_part('day', entered)::int BETWEEN 1 AND 7) AND
              (_yearFilter < 1970 Or date_part('year', entered)::int = _yearFilter);
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        _eventsToDelete := _matchCount;

        If _eventsToDelete = 0 Then
            _jobStepProcessingLogMessage := format('No job step processing log entries were found %s', _thresholdDescription);
        Else
            SELECT COUNT(Event_ID),
                   MIN(Event_ID),
                   MAX(Event_ID)
            INTO _eventsToDelete, _eventIdMin, _eventIdMax
            FROM Tmp_ProcessingLogEventIDs;

            ---------------------------------------------------
            -- Delete the old processing log entries (preview if _infoOnly is true)
            ---------------------------------------------------

            If _infoOnly Then
                INSERT INTO Tmp_EventsToDelete (Target_Table, Event_ID, Job, Step, Target_State, Prev_Target_State, Processor, Entered)
                SELECT 'T_Task_Step_Processing_Log', T.Event_ID, T.Job, T.Step, Null As Target_State, Null As Prev_Target_State, T.Processor, T.Entered
                FROM Tmp_ProcessingLogEventIDs S
                     INNER JOIN logcap.t_task_step_processing_log T
                       ON S.Event_ID = T.Event_ID
                ORDER BY S.Event_ID
                LIMIT 10;

                INSERT INTO Tmp_EventsToDelete (Target_Table, Event_ID, Job, Step, Target_State, Prev_Target_State, Processor, Entered)
                SELECT 'T_Task_Step_Processing_Log', T.Event_ID, T.Job, T.Step, Null As Target_State, Null As Prev_Target_State, T.Processor, T.Entered
                FROM ( SELECT Event_ID
                       FROM Tmp_ProcessingLogEventIDs
                       ORDER BY Event_ID DESC
                       LIMIT 10
                     ) S
                     INNER JOIN logcap.t_task_step_processing_log T
                       ON S.Event_ID = T.Event_ID
                ORDER BY T.Event_ID
                LIMIT 10;

            Else
                DELETE FROM logcap.t_task_step_processing_log Target
                WHERE EXISTS (SELECT 1
                              FROM Tmp_ProcessingLogEventIDs Src
                              WHERE target.event_id = Src.Event_ID);
            End If;

            If _infoOnly Then
                _jobStepProcessingLogMessage := 'Would delete';
            Else
                _jobStepProcessingLogMessage := 'Deleted';
            End If;

             _jobStepProcessingLogMessage := format('%s %s old entries from logcap.t_task_step_processing_log %s; event ID range %s to %s',
                                                    _jobStepProcessingLogMessage, _eventsToDelete, _thresholdDescription, _eventIdMin, _eventIdMax);

            If Not _infoOnly Then
                CALL post_log_entry ('Normal', _jobStepProcessingLogMessage, 'delete_old_capture_task_events_and_historic_logs', _targetSchema => 'logcap');
            End If;
        End If;

        If _infoOnly Then
            RAISE INFO '';

            _formatSpecifier := '%-26s %-10s %-9s %-4s %-12s %-17s %-30s %-20s';

            _infoHead := format(_formatSpecifier,
                                'Target_Table',
                                'Event_ID',
                                'Job',
                                'Step',
                                'Target_State',
                                'Prev_Target_State',
                                'Processor',
                                'Entered'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '--------------------------',
                                         '----------',
                                         '---------',
                                         '----',
                                         '------------',
                                         '-----------------',
                                         '------------------------------',
                                         '--------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Target_Table,
                       Event_ID,
                       Job,
                       Step,
                       Target_State,
                       Prev_Target_State,
                       Processor,
                       Entered
                FROM Tmp_EventsToDelete
                ORDER BY Target_Table, Event_ID
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Target_Table,
                                    _previewData.Event_ID,
                                    _previewData.Job,
                                    _previewData.Step,
                                    _previewData.Target_State,
                                    _previewData.Prev_Target_State,
                                    _previewData.Processor,
                                    _previewData.Entered
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;
        End If;

        ---------------------------------------------------
        -- Find historic log items to delete
        ---------------------------------------------------

        INSERT INTO Tmp_HistoricLogIDs (Entry_ID, Entered)
        SELECT entry_id, entered
        FROM logcap.t_log_entries
        WHERE entered < _dateThreshold AND
              NOT (date_part('month', entered)::int IN (2,8) And date_part('day', entered)::int BETWEEN 1 AND 7) AND
              (_yearFilter < 1970 Or date_part('year', entered)::int = _yearFilter);
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        _logEntriesToDelete := _matchCount;

        If _logEntriesToDelete = 0 Then
            _historicLogMessage := format('No historic log entries were found %s', _thresholdDescription);
        Else
            SELECT COUNT(Entry_ID),
                   MIN(Entry_ID),
                   MAX(Entry_ID)
            INTO _logEntriesToDelete, _eventIdMin, _eventIdMax
            FROM Tmp_HistoricLogIDs;

            ---------------------------------------------------
            -- Delete the old log entries (preview if _infoOnly is true)
            ---------------------------------------------------

            If _infoOnly Then
                -- Cache the 10 oldest log entries to delete
                INSERT INTO Tmp_LogEntriesToDelete (Entry_ID, Posted_By, Entered, Type, Message)
                SELECT T.entry_id, T.posted_by, T.entered, T.type, T.message
                FROM Tmp_HistoricLogIDs S
                     INNER JOIN logcap.t_log_entries T
                       ON S.Entry_ID = T.entry_id
                ORDER BY T.entry_id
                LIMIT 10;

                -- Append the 10 newest log entries to delete
                INSERT INTO Tmp_LogEntriesToDelete (Entry_ID, Posted_By, Entered, Type, Message)
                SELECT T.entry_id, T.Posted_By, T.Entered, T.type, T.Message
                FROM ( SELECT entry_id
                       FROM Tmp_HistoricLogIDs
                       ORDER BY entry_id DESC
                       LIMIT 10
                     ) S
                     INNER JOIN logcap.t_log_entries T
                       ON S.entry_id = T.entry_id
                ORDER BY T.entry_id
                LIMIT 10;

                RAISE INFO '';

                _formatSpecifier := '%-9s %-60s %-20s %-15s %-175s';

                _infoHead := format(_formatSpecifier,
                                    'Entry_ID',
                                    'Posted_By',
                                    'Entered',
                                    'Type',
                                    'Message'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '---------',
                                             '------------------------------------------------------------',
                                             '--------------------',
                                             '---------------',
                                             '-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT Entry_ID,
                           Posted_By,
                           Entered,
                           Type,
                           Message
                    FROM Tmp_LogEntriesToDelete
                    ORDER BY Entry_ID
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Entry_ID,
                                        _previewData.Posted_By,
                                        _previewData.Entered,
                                        _previewData.Type,
                                        _previewData.Message
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                DELETE FROM logcap.t_log_entries Target
                WHERE EXISTS (SELECT Entry_ID
                              FROM Tmp_HistoricLogIDs Src
                              WHERE Target.entry_id = Src.Entry_ID);
            End If;

            If _infoOnly Then
                _historicLogMessage := 'Would delete';
            Else
                _historicLogMessage := 'Deleted';
            End If;

            _historicLogMessage := format('%s %s old entries from logcap.t_log_entries %s; entry ID range %s to %s',
                                          _historicLogMessage, _logEntriesToDelete, _thresholdDescription, _eventIdMin, _eventIdMax);

            If Not _infoOnly Then
                CALL post_log_entry ('Normal', _historicLogMessage, 'delete_old_capture_task_events_and_historic_logs', _targetSchema => 'logcap');
            End If;
        End If;

        If _jobEventsMessage <> '' Then
            RAISE INFO '';
            RAISE INFO '%', _jobEventsMessage;
            _message := public.append_to_text(_message, _jobEventsMessage);
        End If;

        If _jobStepEventsMessage <> '' Then
            RAISE INFO '';
            RAISE INFO '%', _jobStepEventsMessage;
            _message := public.append_to_text(_message, _jobStepEventsMessage);
        End If;

        If _jobStepProcessingLogMessage <> '' Then
            RAISE INFO '';
            RAISE INFO '%', _jobStepProcessingLogMessage;
            _message := public.append_to_text(_message, _jobStepProcessingLogMessage);
        End If;

        If _historicLogMessage <> '' Then
            RAISE INFO '';
            RAISE INFO '%', _historicLogMessage;
            _message := public.append_to_text(_message, _historicLogMessage);
        End If;

        DROP TABLE Tmp_TaskEventIDs;
        DROP TABLE Tmp_TaskStepEventIDs;
        DROP TABLE Tmp_ProcessingLogEventIDs;
        DROP TABLE Tmp_HistoricLogIDs;
        DROP TABLE Tmp_EventsToDelete;
        DROP TABLE Tmp_LogEntriesToDelete;

        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => false);

        If Not _infoOnly Then
            CALL post_log_entry ('Error', _exceptionMessage, 'delete_old_capture_task_events_and_historic_logs', _targetSchema => 'logcap');
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_TaskEventIDs;
    DROP TABLE IF EXISTS Tmp_TaskStepEventIDs;
    DROP TABLE IF EXISTS Tmp_ProcessingLogEventIDs;
    DROP TABLE IF EXISTS Tmp_HistoricLogIDs;
    DROP TABLE IF EXISTS Tmp_EventsToDelete;
    DROP TABLE IF EXISTS Tmp_LogEntriesToDelete;
END
$$;


ALTER PROCEDURE logcap.delete_old_capture_task_events_and_historic_logs(IN _infoonly boolean, IN _yearfilter integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

