--
-- Name: find_log_entry(text, text, text, text, text, text, integer, refcursor, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.find_log_entry(IN _entryid text DEFAULT ''::text, IN _postedby text DEFAULT ''::text, IN _postingtimeafter text DEFAULT ''::text, IN _postingtimebefore text DEFAULT ''::text, IN _entrytype text DEFAULT ''::text, IN _messagetext text DEFAULT ''::text, IN _maxrowcount integer DEFAULT 50, INOUT _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Return result set of main log satisfying the search parameters
**
**      This procedure is used by unit tests in class StoredProcedureTests in the PRISM Class Library,
**      including to verify that data in the _results refcursor is auto-converted to a result set
**
**  Arguments:
**    _entryID              Entry_ID to find in t_log_entries
**    _postedBy             Log entry source name
**    _postingTimeAfter     Minimum log time threshold
**    _postingTimeBefore    Maximum log time threshold
**    _entryType            Log entry type (typically 'Normal', 'Error', 'Warning', or 'Progress')
**    _messageText          Text to find in the log message
**    _results              Output: reference cursor used to return the results
**    _maxRowCount          Maximum number of results to return (0 to return all results)
**    _message              Output: message (if an error)
**    _returnCode           Output: return code (if an error)
**    _infoLevel            0 to request a task, 1 to preview the capture task job that would be returned; 2 to include details on the available capture tasks
**
**
**  Use this to view the data returned by the _results cursor
**
**      BEGIN;
**          CALL find_log_entry(_entryType => 'Normal', _messageText => 'Backup', _maxRowCount => 15);
**          FETCH ALL FROM _results;
**      END;
**
**  Alternatively, use an anonymous code block:

    DO
    LANGUAGE plpgsql
    $$
    DECLARE
        _results refcursor;
        _message text;
        _returnCode text;
        _logEntry record;
        _itemsShown int = 0;
    BEGIN
        CALL find_log_entry(_entryType => 'Normal', _messageText => 'Backup', _results => _results, _message => _message, _returnCode => _returnCode);

        WHILE true
        LOOP
            FETCH NEXT FROM _results
            INTO _logEntry;

            If Not FOUND Or _itemsShown > 5 Then
                 EXIT;
            End If;

            RAISE INFO 'ID %, type %, posted by %: %', _logEntry.entry, _logEntry.type, _logEntry.posted_by, _logEntry.message;

            _itemsShown := _itemsShown + 1;
        END LOOP;
    END
    $$;

**
**  Auth:   grk
**  Date:   08/23/2006
**          12/20/2006 mem - Now querying V_Log_Report using dynamic SQL (Ticket #349)
**          01/24/2008 mem - Switched the @i_ variables to use the datetime data type (Ticket #225)
**          03/23/2017 mem - Use Try_Convert instead of Convert
**                         - Use sp_executesql
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          01/05/2023 mem - Use new column names in V_Log_Report
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          06/05/2023 mem - Add _maxRowCount and rename procedure arguments
**                         - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _entryIDValue int;
    _postedByWildcard text;
    _earliestPostingTime timestamp;
    _latestPostingTime timestamp;
    _typeWildcard text;
    _messageWildcard text;
    _sql text;
    _sqlWhere text := '';
    _sqlWithFilters text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------

    _entryIDValue        := public.try_cast(_EntryID, null::int);

    _postedByWildcard    := '%' || _PostedBy || '%';

    _earliestPostingTime := public.try_cast(_PostingTimeAfter,  null::timestamp);
    _latestPostingTime   := public.try_cast(_PostingTimeBefore, null::timestamp);

    _typeWildcard        := '%' || _EntryType || '%';

    _messageWildcard     := '%' || _MessageText || '%';

    _maxRowCount         := Coalesce(_maxRowCount, 0);

    ---------------------------------------------------
    -- Construct the query
    ---------------------------------------------------

   _sql := ' SELECT * FROM V_Log_Report';

    If _entryIDValue > 0 Then
        _sqlWhere := format('%s AND (Entry_ID = $1)', _sqlWhere);
    End If;

    If char_length(_PostedBy) > 0 Then
        _sqlWhere := format('%s AND (Posted_By LIKE $2)', _sqlWhere);
    End If;

    If char_length(_PostingTimeAfter) > 0 Then
        _sqlWhere := format('%s AND (Entered >= $3)', _sqlWhere);
    End If;

    If char_length(_PostingTimeBefore) > 0 Then
        _sqlWhere := format('%s AND (Entered < $4)', _sqlWhere);
    End If;

    If char_length(_EntryType) > 0 Then
        _sqlWhere := format('%s AND (Type LIKE $5)', _sqlWhere);
    End If;

    If char_length(_MessageText) > 0 Then
        _sqlWhere := format('%s AND (Message LIKE $6)', _sqlWhere);
    End If;

    If char_length(_sqlWhere) > 0 Then
        -- One or more filters are defined
        -- Remove the first AND from the start of _sqlWhere and add the word WHERE
        _sqlWhere := format('WHERE %s', Substring(_sqlWhere, 6, char_length(_sqlWhere) - 5));
        _sql := format('%s %s', _sql, _sqlWhere);
    End If;

    _sql := format('%s ORDER BY entry %s', _sql, CASE WHEN _maxRowCount > 0 THEN 'Desc' ELSE 'Asc' END);

    If _maxRowCount > 0 Then
        _sql := format('%s LIMIT %s', _sql, _maxRowCount);
    End If;

    -- RAISE INFO 'Query: %', _sql;

    If char_length(_sqlWhere) > 0 Then

        _sqlWithFilters := _sql;

        If _entryIDValue > 0 Then
            _sqlWithFilters := Replace(_sqlWithFilters, '$1', _entryIDValue::text);
        End If;

        If char_length(_PostedBy) > 0 Then
            _sqlWithFilters := Replace(_sqlWithFilters, '$2', Coalesce('''' || _postedByWildcard || '''', ''));
        End If;

        If char_length(_PostingTimeAfter) > 0 Then
            _sqlWithFilters := Replace(_sqlWithFilters, '$3', Coalesce('''' || _earliestPostingTime || '''', 'Null'));
        End If;

        If char_length(_PostingTimeBefore) > 0 Then
            _sqlWithFilters := Replace(_sqlWithFilters, '$4', Coalesce('''' || _latestPostingTime || '''', 'Null'));
        End If;

        If char_length(_EntryType) > 0 Then
            _sqlWithFilters := Replace(_sqlWithFilters, '$5', Coalesce('''' || _typeWildcard || '''', ''));
        End If;

        If char_length(_MessageText) > 0 Then
            _sqlWithFilters := Replace(_sqlWithFilters, '$6', Coalesce('''' || _messageWildcard || '''', ''));
        End If;

        RAISE INFO 'Query: %', _sqlWithFilters;
    End If;

    ---------------------------------------------------
    -- Run the query
    ---------------------------------------------------

    Open _results For
        EXECUTE _sql
        USING _entryIDValue, _postedByWildcard, _earliestPostingTime, _latestPostingTime, _typeWildcard, _messageWildcard;

    _message := 'To see the results, use: "FETCH ALL FROM _results"';

    RAISE INFO '%', _message;

END
$_$;


ALTER PROCEDURE public.find_log_entry(IN _entryid text, IN _postedby text, IN _postingtimeafter text, IN _postingtimebefore text, IN _entrytype text, IN _messagetext text, IN _maxrowcount integer, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE find_log_entry(IN _entryid text, IN _postedby text, IN _postingtimeafter text, IN _postingtimebefore text, IN _entrytype text, IN _messagetext text, IN _maxrowcount integer, INOUT _results refcursor, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.find_log_entry(IN _entryid text, IN _postedby text, IN _postingtimeafter text, IN _postingtimebefore text, IN _entrytype text, IN _messagetext text, IN _maxrowcount integer, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) IS 'FindLogEntry';

--
-- Name: PROCEDURE find_log_entry(IN _entryid text, IN _postedby text, IN _postingtimeafter text, IN _postingtimebefore text, IN _entrytype text, IN _messagetext text, IN _maxrowcount integer, INOUT _results refcursor, INOUT _message text, INOUT _returncode text); Type: ACL; Schema: public; Owner: d3l243
--

GRANT ALL ON PROCEDURE public.find_log_entry(IN _entryid text, IN _postedby text, IN _postingtimeafter text, IN _postingtimebefore text, IN _entrytype text, IN _messagetext text, IN _maxrowcount integer, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) TO dmswebuser;

