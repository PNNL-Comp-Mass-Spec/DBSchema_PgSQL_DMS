--
-- Name: alterenteredbyuser(text, text, integer, text, integer, integer, text, text, text, text, integer, integer); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE PROCEDURE mc.alterenteredbyuser(_targettablename text, _targetidcolumnname text, _targetid integer, _newuser text, _applytimefilter integer DEFAULT 1, _entrytimewindowseconds integer DEFAULT 15, _entrydatecolumnname text DEFAULT 'entered'::text, _enteredbycolumnname text DEFAULT 'entered_by'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, _infoonly integer DEFAULT 0, _previewsql integer DEFAULT 0)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the entered_by column for the specified row in the given table to contain _newUser
**
**      If _applyTimeFilter is non-zero, only matches entries made within the last _entryTimeWindowSeconds seconds
**
**      Use @infoOnly = 1 to preview updates
**
**  Arguments:
**    _targetTableName          Table to update
**    _targetIDColumnName       ID column name
**    _targetID                 ID of the entry to update
**    _newUser                  New username to add to the entered_by field
**    _applyTimeFilter          If 1, filters by the current date and time; if 0, looks for the most recent matching entry
**    _entryTimeWindowSeconds   Only used if _applyTimeFilter = 1
**    _entryDateColumnName      Column name to use when _applyTimeFilter is non-zero
**    _enteredByColumnName      Column name to update the username
**    _message                  Warning or status message
**    _returnCode               Empty or '00000' if no error, otherwise, a SQLSTATE code. User-codes start with 'U'
**    _infoOnly                 If 1, preview updates
**    _previewSql               If 1, show the SQL that would be used
**
**  Auth:   mem
**  Date:   03/25/2008 mem - Initial version (Ticket: #644)
**          05/23/2008 mem - Expanded @EntryDescription to varchar(512)
**          01/25/2020 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _entryDateStart timestamp;
    _entryDateEnd timestamp;
    _entryDescription text := '';
    _entryIndex int;
    _matchIndex int;
    _enteredBy text;
    _targetIDMatch int;
    _enteredByNew text := '';
    _currentTime timestamp := CURRENT_TIMESTAMP;
    _s text;
    _entryFilterSql text := '';
    _lookupResults record;
    _result int;
    _sqlstate text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _newUser := Coalesce(_newUser, '');
    _applyTimeFilter := Coalesce(_applyTimeFilter, 0);
    _entryTimeWindowSeconds := Coalesce(_entryTimeWindowSeconds, 15);
    _message := '';
    _returnCode := '';
    _infoOnly := Coalesce(_infoOnly, 0);
    _previewSql := Coalesce(_previewSql, 0);

    If _targetTableName Is Null Or _targetIDColumnName Is Null Or _targetID Is Null Then
        _message := '_targetTableName and _targetIDColumnName and _targetID must be defined; unable to continue';
        _returnCode := 'U5201';
        Return;
    End If;

    If char_length(_newUser) = 0 Then
        _message := '_newUser is empty; unable to continue';
        _returnCode := 'U5202';
        Return;
    End If;

    _entryDescription := 'ID ' || _targetID::text || ' in table ' || _targetTableName || ' (column ' || _targetIDColumnName || ')';

    _s := format(
            'SELECT %I as target_id_match, %I as entered_by '
            'FROM %I '
            'WHERE %I = %s',
            _targetIDColumnName, _enteredByColumnName,
            _targetTableName,
            _targetIDColumnName, _targetID);

    If _applyTimeFilter <> 0 And _entryTimeWindowSeconds >= 1 Then
        ------------------------------------------------
        -- Filter using the current date/time
        ------------------------------------------------
        --
        _entryDateStart := _currentTime - (_entryTimeWindowSeconds || ' seconds')::INTERVAL;
        _entryDateEnd   := _currentTime + INTERVAL '1 second';

        If _infoOnly <> 0 Then
            RAISE INFO 'Filtering on entries dated between % and % (Window = % seconds)',
                to_char(_entryDateStart, 'yyyy-mm-dd hh24:mi:ss'),
                to_char(_entryDateEnd,   'yyyy-mm-dd hh24:mi:ss'),
                _entryTimeWindowSeconds;
        End If;

        _entryFilterSql := format(
                            '%I between ''%s'' And ''%s''',
                             _entryDateColumnName,
                            to_char(_entryDateStart, 'yyyy-mm-dd hh24:mi:ss'),
                            to_char(_entryDateEnd,   'yyyy-mm-dd hh24:mi:ss'));

        _s := _s || ' AND ' || _entryFilterSql;

        _entryDescription := _entryDescription || ' with ' || _entryFilterSql;
    End If;

    If _previewSql <> 0 Then
        RAISE INFO '%;', _s;
        _enteredBy := session_user || '_simulated';
        _targetIDMatch := _targetID;
    Else
        EXECUTE _s INTO _lookupResults;
        _enteredBy := _lookupResults.entered_by;
        _targetIDMatch := _lookupResults.target_id_match;
    End If;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _previewSql = 0 AND (_myRowCount <= 0 Or _targetIDMatch <> _targetID) Then
        _message := 'Match not found for ' || _entryDescription;
    Else
        -- Confirm that _enteredBy doesn't already contain _newUser
        -- If it does, there's no need to update it

        _matchIndex := position(_newUser in _enteredBy);
        If _matchIndex > 0 Then
            _message := 'Entry ' || _entryDescription || ' is already attributed to ' || _newUser || ': "' || _enteredBy || '"';
            Return;
        End If;

        -- Look for a semicolon in _enteredBy

        _matchIndex := position(';' in _enteredBy);

        If _matchIndex > 0 Then
            _enteredByNew := _newUser || ' (via ' || SubString(_enteredBy, 1, _matchIndex-1) || ')' || SubString(_enteredBy, _matchIndex, char_length(_enteredBy));
        Else
            _enteredByNew := _newUser || ' (via ' || _enteredBy || ')';
        End If;

        If char_length(Coalesce(_enteredByNew, '')) > 0 Then

            If _infoOnly = 0 Then

                _s := format(
                        'UPDATE %I '
                        'SET %I = ''%s'' '
                        'WHERE %I = %s',
                        _targetTableName,
                        _enteredByColumnName, _enteredByNew,
                        _targetIDColumnName, _targetID);

                If char_length(_entryFilterSql) > 0 Then
                    _s := _s || ' AND ' || _entryFilterSql;
                End If;

                If _previewSql <> 0 Then
                    RAISE INFO '%;', _s;
                Else
                    EXECUTE _s;
                End If;
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                If _previewSql = 0 Then
                    _message := 'Updated ';
                Else
                    _message := 'SQL previewed for updating ';
                End If;

                _message := _message || _entryDescription || ' to indicate "' || _enteredByNew || '"';

            Else
                _s := format(
                        'SELECT *, ''' || _enteredByNew || ''' AS Entered_By_New '
                        'FROM %I '
                        'WHERE %I = %s',
                        _targetTableName,
                        _targetIDColumnName, _targetID);

                If char_length(_entryFilterSql) > 0 Then
                    _s := _s || ' AND ' || _entryFilterSql;
                End If;

                If _previewSql <> 0 Then
                    RAISE INFO '%;', _s;
                Else
                    Execute _s;
                End If;
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                _message := 'Would update ' || _entryDescription || ' to indicate "' || _enteredByNew || '"';
            End If;

        Else
            _message := 'Match not found; unable to continue';
        End If;

    End If;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := 'Error updating ' || _entryDescription || ': ' || _exceptionMessage;
    _returnCode := _sqlstate;

    -- Future: call PostLogEntry 'Error', _message, 'AlterEventLogEntryUser'
    INSERT INTO t_log_entries (posted_by, type, message)
    VALUES ('AlterEventLogEntryUser', 'Error', _message);

END
$$;


ALTER PROCEDURE mc.alterenteredbyuser(_targettablename text, _targetidcolumnname text, _targetid integer, _newuser text, _applytimefilter integer, _entrytimewindowseconds integer, _entrydatecolumnname text, _enteredbycolumnname text, INOUT _message text, INOUT _returncode text, _infoonly integer, _previewsql integer) OWNER TO d3l243;

--
-- Name: PROCEDURE alterenteredbyuser(_targettablename text, _targetidcolumnname text, _targetid integer, _newuser text, _applytimefilter integer, _entrytimewindowseconds integer, _entrydatecolumnname text, _enteredbycolumnname text, INOUT _message text, INOUT _returncode text, _infoonly integer, _previewsql integer); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.alterenteredbyuser(_targettablename text, _targetidcolumnname text, _targetid integer, _newuser text, _applytimefilter integer, _entrytimewindowseconds integer, _entrydatecolumnname text, _enteredbycolumnname text, INOUT _message text, INOUT _returncode text, _infoonly integer, _previewsql integer) IS 'AlterEnteredByUser';

