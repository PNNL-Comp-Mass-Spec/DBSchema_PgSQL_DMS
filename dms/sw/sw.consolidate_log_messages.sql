--
-- Name: consolidate_log_messages(text, text, boolean, boolean, boolean); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.consolidate_log_messages(_messagetype text DEFAULT 'Error'::text, _messagefilter text DEFAULT ''::text, _keepfirstmessageonly boolean DEFAULT false, _changeerrorstoerrorignore boolean DEFAULT true, _infoonly boolean DEFAULT true) RETURNS TABLE(entry_id integer, posted_by public.citext, entered timestamp without time zone, type public.citext, message public.citext, entered_by public.citext, status public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Deletes duplicate messages in sw.t_log_entries,
**          keeping the first and last message
**          (or, optionally only the first message)
**
**  Arguments:
**    _messageFilter               Optional filter for the message text; will auto-add % wildcards if it does not contain a % and no messages are matched
**    _keepFirstMessageOnly        When false, keep the first and last message; when true, only keep the first message
**    _changeErrorsToErrorIgnore   When true, if _messageType is 'Error' will update messages in sw.t_log_entries to have type 'ErrorIgnore' (if duplicates are removed)
**
**  Usage:
**
**      SELECT * FROM sw.consolidate_log_messages (_infoOnly => true);
**      SELECT * FROM sw.consolidate_log_messages (_changeErrorsToErrorIgnore => false, _infoOnly => true);
**      SELECT * FROM sw.consolidate_log_messages ('Error', '%132%', _keepFirstMessageOnly => false, _infoOnly => true);
**      SELECT * FROM sw.consolidate_log_messages ('Error', '%132%', _infoOnly => false);
**
**  Auth:   mem
**  Date:   01/14/2019 mem - Initial version
**          10/12/2022 mem - Ported to PostgreSQL
**          05/10/2023 mem - Capitalize procedure name sent to post_log_entry
**
*****************************************************/
DECLARE
    _message text;

    _deletedMessageCount int := 0;
    _duplicateMessageCount int := 0;
    _statusKeep citext;
    _statusDelete citext;
    _callingProcName text;
    _retriesRemaining int := 2;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _messageType := Trim(Coalesce(_messageType, ''));
    _messageFilter := Coalesce(_messageFilter, '');
    _keepFirstMessageOnly := Coalesce(_keepFirstMessageOnly, false);
    _changeErrorsToErrorIgnore := Coalesce(_changeErrorsToErrorIgnore, true);
    _infoOnly := Coalesce(_infoOnly, false);

    If char_length(_messageType) = 0 Then
        RAISE WARNING '%', '_messageType cannot be empty';
        RETURN;
    End If;

    CREATE TEMP TABLE Tmp_DuplicateMessages (
        Message text,
        Entry_ID_First int,
        Entry_ID_Last int
    );

    CREATE TEMP TABLE Tmp_MessagesToDelete (
        Entry_ID int
    );

    ----------------------------------------------------
    -- Find duplicate log entries
    ----------------------------------------------------
    --
    If _messageFilter = '' Then
        INSERT INTO Tmp_DuplicateMessages( message, Entry_ID_First, Entry_ID_Last )
        SELECT L.message, Min(L.entry_id), Max(L.entry_id)
        FROM sw.t_log_entries L
        WHERE L.type::citext = _messageType::citext
        GROUP BY L.message
        HAVING Count(*) >= 2;
    Else
        WHILE _retriesRemaining > 0
        LOOP
            INSERT INTO Tmp_DuplicateMessages( message, Entry_ID_First, Entry_ID_Last )
            SELECT L.message, Min(L.entry_id), Max(L.entry_id)
            FROM sw.t_log_entries L
            WHERE L.type::citext = _messageType::citext AND
                  L.message::citext LIKE _messageFilter::citext
            GROUP BY L.message
            HAVING Count(*) >= 2;

            If FOUND Or _messageFilter SIMILAR TO '%[%]%' Then
                _retriesRemaining := 0;
            Else
                _messageFilter := '%' || _messageFilter || '%';
                _retriesRemaining := _retriesRemaining - 1;
            End If;

        END LOOP;
    End If;

    ----------------------------------------------------
    -- Find the messages that should be deleted,
    -- keeping only the first one if _keepFirstMessageOnly is true
    ----------------------------------------------------
    --
    If Not _keepFirstMessageOnly Then
        INSERT INTO Tmp_MessagesToDelete
        SELECT L.entry_id
        FROM sw.t_log_entries L
             INNER JOIN Tmp_DuplicateMessages D
               ON L.message = D.message AND
                  L.entry_id <> D.Entry_ID_First AND
                  L.entry_id <> D.Entry_ID_Last
        ORDER BY L.message, L.entry_id;
    Else
        INSERT INTO Tmp_MessagesToDelete
        SELECT L.entry_id
        FROM sw.t_log_entries L
             INNER JOIN Tmp_DuplicateMessages D
               ON L.message = D.message AND
                  L.entry_id <> D.Entry_ID_First
        ORDER BY L.message, L.entry_id;
    End If;

    ----------------------------------------------------
    -- Show the duplicate messages, along with an action message
    ----------------------------------------------------
    --
    If Not _infoOnly Then
        _statusKeep := 'Retained';
        _statusDelete := 'Deleted';
    Else
        _statusKeep := 'Keep';
        _statusDelete := 'Delete';
    End If;

    RETURN QUERY
    SELECT L.entry_id,
           L.posted_by,
           L.entered,
           L.type,
           L.message,
           L.entered_by,
           CASE
               WHEN D.Entry_ID IS NULL THEN _statusKeep
               ELSE _statusDelete
           END AS Status
    FROM sw.t_log_entries L
         LEFT OUTER JOIN Tmp_MessagesToDelete D
           ON L.entry_id = D.entry_id
    WHERE L.message IN ( SELECT Duplicates.message FROM Tmp_DuplicateMessages Duplicates)
    ORDER BY L.message, L.entry_id;

    If Not _infoOnly Then

        ----------------------------------------------------
        -- Remove the duplicates
        ----------------------------------------------------

        -- Option 1:
        -- DELETE FROM sw.t_log_entries
        -- WHERE entry_id IN ( SELECT entry_id FROM Tmp_MessagesToDelete );

        -- Option 2 (this is the preferred form, though in this case both options have the same execution plan)
        DELETE FROM sw.t_log_entries
        WHERE EXISTS (SELECT D.entry_id
                      FROM Tmp_MessagesToDelete D
                      WHERE D.entry_id = sw.t_log_entries.entry_id);
        --
        GET DIAGNOSTICS _deletedMessageCount = ROW_COUNT;

        SELECT Count(*)
        INTO _duplicateMessageCount
        FROM Tmp_DuplicateMessages;

        _message := format ('Found %s duplicate %s in sw.t_log_entries; deleted %s %s',
                            _duplicateMessageCount, public.check_plural(_duplicateMessageCount, 'message', 'messages'),
                            _deletedMessageCount,   public.check_plural(_deletedMessageCount, 'log entry', 'log entries'));

        RAISE INFO '%', _message;

        If _duplicateMessageCount > 0 Or _deletedMessageCount > 0 Then
            CALL public.post_log_entry ('Normal', _message, 'Consolidate_Log_Messages', 'sw');
        End If;

        If _deletedMessageCount > 0 And _changeErrorsToErrorIgnore Then
            UPDATE sw.t_log_entries target
            SET type = 'ErrorIgnore'
            WHERE target.type = 'Error' AND
                  target.message IN ( SELECT Duplicates.message
                                      FROM Tmp_DuplicateMessages Duplicates);
        End If;

    End If;

    DROP TABLE Tmp_DuplicateMessages;
    DROP TABLE Tmp_MessagesToDelete;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState         = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionDetail  = pg_exception_detail,
            _exceptionContext = pg_exception_context;

    _message := local_error_handler (
                    _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                    _callingProcLocation => '', _logError => true);

    RAISE WARNING '%', _message;

    DROP TABLE IF EXISTS Tmp_DuplicateMessages;
    DROP TABLE IF EXISTS Tmp_MessagesToDelete;
END
$$;


ALTER FUNCTION sw.consolidate_log_messages(_messagetype text, _messagefilter text, _keepfirstmessageonly boolean, _changeerrorstoerrorignore boolean, _infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION consolidate_log_messages(_messagetype text, _messagefilter text, _keepfirstmessageonly boolean, _changeerrorstoerrorignore boolean, _infoonly boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.consolidate_log_messages(_messagetype text, _messagefilter text, _keepfirstmessageonly boolean, _changeerrorstoerrorignore boolean, _infoonly boolean) IS 'ConsolidateLogMessages';

