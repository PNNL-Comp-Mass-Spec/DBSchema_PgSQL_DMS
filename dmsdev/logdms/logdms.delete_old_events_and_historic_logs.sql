--
-- Name: delete_old_events_and_historic_logs(boolean, integer, text, text); Type: PROCEDURE; Schema: logdms; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE logdms.delete_old_events_and_historic_logs(IN _infoonly boolean DEFAULT false, IN _yearfilter integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete entries over 5 years old in logdms.t_event_log and logdms.t_log_entries
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
**  Auth:   mem
**  Date:   06/08/2022 mem - Initial version
**          06/09/2022 mem - Rename T_Historic_Log_Entries to T_Log_Entries
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

    _eventMessage text = '';
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

        CREATE TEMP TABLE Tmp_EventLogIDs (
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
            Event_ID int NOT NULL,
            Target_Type int NULL,
            Target_ID int NULL,
            Target_State smallint NULL,
            Prev_Target_State smallint NULL,
            Entered timestamp NULL,
            PRIMARY KEY ( Event_ID)
        );

        CREATE TEMP TABLE Tmp_LogEntriesToDelete (
            Entry_ID  int NOT NULL,
            Posted_By citext NULL,
            Entered   timestamp NOT NULL,
            Type      citext NULL,
            Message   citext NULL
        );

        ---------------------------------------------------
        -- Define the date threshold by subtracting five years from January 1 of this year
        ---------------------------------------------------

        _dateThreshold := make_date(date_part('year', CURRENT_TIMESTAMP)::int, 1, 1) - Interval '5 years';

        _thresholdDescription := format('using date threshold %s', Left(public.timestamp_text(_dateThreshold), 10));

        If _yearFilter >= 1970 Then
            _thresholdDescription := format('%s and year filter %s', _thresholdDescription, _yearFilter);
        End If;

        ---------------------------------------------------
        -- Find event log items to delete
        ---------------------------------------------------

        INSERT INTO Tmp_EventLogIDs (Event_ID, Entered)
        SELECT Event_ID, Entered
        FROM logdms.t_event_log
        WHERE entered < _dateThreshold AND
              NOT (date_part('month', entered)::int IN (2,8) And date_part('day', entered)::int BETWEEN 1 AND 7) AND
              (_yearFilter < 1970 Or date_part('year', entered)::int = _yearFilter);
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        _eventsToDelete := _matchCount;

        If _eventsToDelete = 0 Then
            _eventMessage := format('No event log entries were found %s', _thresholdDescription);
        Else
            SELECT COUNT(Event_ID),
                   MIN(Event_ID),
                   MAX(Event_ID)
            INTO _eventsToDelete, _eventIdMin, _eventIdMax
            FROM Tmp_EventLogIDs;

            ---------------------------------------------------
            -- Delete the old events (preview if _infoOnly is true)
            ---------------------------------------------------

            If _infoOnly Then
                -- Cache the 10 oldest events to delete
                INSERT INTO Tmp_EventsToDelete (Event_ID, Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
                SELECT T.Event_ID, T.Target_Type, T.Target_ID, T.Target_State, T.Prev_Target_State, T.Entered
                FROM Tmp_EventLogIDs S
                     INNER JOIN logdms.t_event_log T
                       ON S.Event_ID = T.Event_ID
                ORDER BY S.Event_ID
                LIMIT 10;

                -- Append the 10 newest events to delete
                INSERT INTO Tmp_EventsToDelete (Event_ID, Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
                SELECT T.Event_ID, T.Target_Type, T.Target_ID, T.Target_State, T.Prev_Target_State, T.Entered
                FROM ( SELECT Event_ID
                       FROM Tmp_EventLogIDs
                       ORDER BY Event_ID DESC
                       LIMIT 10
                     ) S
                     INNER JOIN logdms.t_event_log T
                       ON S.Event_ID = T.Event_ID
                ORDER BY T.Event_ID
                LIMIT 10;

                RAISE INFO '';

                _formatSpecifier := '%-8s %-11s %-10s %-12s %-17s %-20s';

                _infoHead := format(_formatSpecifier,
                                    'Event_ID',
                                    'Target_Type',
                                    'Target_ID',
                                    'Target_State',
                                    'Prev_Target_State',
                                    'Entered'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '--------',
                                             '-----------',
                                             '----------',
                                             '------------',
                                             '-----------------',
                                             '--------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT Event_ID,
                           Target_Type,
                           Target_ID,
                           Target_State,
                           Prev_Target_State,
                           Entered
                    FROM Tmp_EventsToDelete
                    ORDER BY Event_ID
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Event_ID,
                                        _previewData.Target_Type,
                                        _previewData.Target_ID,
                                        _previewData.Target_State,
                                        _previewData.Prev_Target_State,
                                        _previewData.Entered
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                DELETE FROM logdms.t_event_log Target
                WHERE EXISTS (SELECT 1
                              FROM Tmp_EventLogIDs Src
                              WHERE Target.event_id = Src.Event_ID);
            End If;

            If _infoOnly Then
                _eventMessage := 'Would delete';
            Else
                _eventMessage := 'Deleted';
            End If;

            _eventMessage := format('%s %s old entries from logdms.t_event_log %s; event ID range %s to %s',
                                    _eventMessage, _eventsToDelete, _thresholdDescription, _eventIdMin, _eventIdMax);

            If Not _infoOnly Then
                CALL post_log_entry ('Normal', _eventMessage, 'delete_old_events_and_historic_logs', _targetSchema => 'logdms');
            End If;
        End If;

        ---------------------------------------------------
        -- Find historic log items to delete
        ---------------------------------------------------

        INSERT INTO Tmp_HistoricLogIDs (Entry_ID, Entered)
        SELECT entry_id, entered
        FROM logdms.t_log_entries
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
                     INNER JOIN logdms.t_log_entries T
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
                     INNER JOIN logdms.t_log_entries T
                       ON S.entry_id = T.entry_id
                ORDER BY T.entry_id
                LIMIT 10;

                RAISE INFO '';

                _formatSpecifier := '%-8s %-60s %-20s %-15s %-175s';

                _infoHead := format(_formatSpecifier,
                                    'Entry_ID',
                                    'Posted_By',
                                    'Entered',
                                    'Type',
                                    'Message'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '--------',
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
                DELETE FROM logdms.t_log_entries Target
                WHERE EXISTS (SELECT Entry_ID
                              FROM Tmp_HistoricLogIDs Src
                              WHERE Target.entry_id = Src.Entry_ID);
            End If;

            If _infoOnly Then
                _historicLogMessage := 'Would delete';
            Else
                _historicLogMessage := 'Deleted';
            End If;

            _historicLogMessage := format('%s %s old entries from logdms.t_log_entries %s; entry ID range %s to %s',
                                          _historicLogMessage, _logEntriesToDelete, _thresholdDescription, _eventIdMin, _eventIdMax);

            If Not _infoOnly Then
                CALL post_log_entry ('Normal', _historicLogMessage, 'delete_old_events_and_historic_logs', _targetSchema => 'logdms');
            End If;
        End If;

        If _eventMessage <> '' Then
            RAISE INFO '';
            RAISE INFO '%', _eventMessage;
            _message := public.append_to_text(_message, _eventMessage);
        End If;

        If _historicLogMessage <> '' Then
            RAISE INFO '';
            RAISE INFO '%', _historicLogMessage;
            _message := public.append_to_text(_message, _historicLogMessage);
        End If;

        DROP TABLE Tmp_EventLogIDs;
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
            CALL post_log_entry ('Error', _exceptionMessage, 'delete_old_events_and_historic_logs', _targetSchema => 'logdms');
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_EventLogIDs;
    DROP TABLE IF EXISTS Tmp_HistoricLogIDs;
    DROP TABLE IF EXISTS Tmp_EventsToDelete;
    DROP TABLE IF EXISTS Tmp_LogEntriesToDelete;
END
$$;


ALTER PROCEDURE logdms.delete_old_events_and_historic_logs(IN _infoonly boolean, IN _yearfilter integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

