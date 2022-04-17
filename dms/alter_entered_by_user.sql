--
-- Name: alter_entered_by_user(text, text, text, integer, text, integer, integer, text, text, text, integer, integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.alter_entered_by_user(IN _targettableschema text, IN _targettablename text, IN _targetidcolumnname text, IN _targetid integer, IN _newuser text, IN _applytimefilter integer DEFAULT 1, IN _entrytimewindowseconds integer DEFAULT 15, IN _entrydatecolumnname text DEFAULT 'entered'::text, IN _enteredbycolumnname text DEFAULT 'entered_by'::text, INOUT _message text DEFAULT ''::text, IN _infoonly integer DEFAULT 0, IN _previewsql integer DEFAULT 0)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Updates the entered_by column for the specified row in the given table to contain _newUser
**
**  Arguments:
**    _targetTableSchema        Schema of the table to update; if empty or null, assumes "public"
**    _targetTableName          Table to update
**    _targetIDColumnName       ID column name
**    _targetID                 ID of the entry to update
**    _newUser                  New username to add to the entered_by field
**    _applyTimeFilter          If 1, filters by the current date and time; if 0, looks for the most recent matching entry
**    _entryTimeWindowSeconds   Only used if _applyTimeFilter = 1
**    _entryDateColumnName      Column name to use when _applyTimeFilter is non-zero
**    _enteredByColumnName      Column name to update the username
**    _message                  Warning or status message
**    _infoOnly                 If 1, preview updates
**    _previewSql               If 1, show the SQL that would be used
**
**  Auth:   mem
**  Date:   03/25/2008 mem - Initial version (Ticket: #644)
**          05/23/2008 mem - Expanded @EntryDescription to varchar(512)
**          01/25/2020 mem - Ported to PostgreSQL
**          01/28/2020 mem - Add argument _targetTableSchema
**                         - Remove exception handler and remove argument _returnCode
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
    _entryDateFilterSqlWithVariables text := '';
    _entryDateFilterSqlWithValues text := '';
    _lookupResults record;
BEGIN

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _targetTableSchema := COALESCE(_targetTableSchema, '');
    If (char_length(_targetTableSchema) = 0) Then
        _targetTableSchema := 'public';
    End If;

    _newUser := Coalesce(_newUser, '');
    _applyTimeFilter := Coalesce(_applyTimeFilter, 0);
    _entryTimeWindowSeconds := Coalesce(_entryTimeWindowSeconds, 15);
    _message := '';
    _infoOnly := Coalesce(_infoOnly, 0);
    _previewSql := Coalesce(_previewSql, 0);

    If _targetTableName Is Null Or _targetIDColumnName Is Null Or _targetID Is Null Then
        _message := '_targetTableName and _targetIDColumnName and _targetID must be defined; unable to continue';
        RAISE EXCEPTION '%', _message;
    End If;

    If char_length(_newUser) = 0 Then
        _message := '_newUser is empty; unable to continue';
        RAISE EXCEPTION '%', _message;
    End If;

    _entryDescription := 'ID ' || _targetID::text || ' in table ' || _targetTableName || ' (column ' || _targetIDColumnName || ')';

    _s := format(
            'SELECT %I as target_id_match, %I as entered_by '
            'FROM %I.%I '
            'WHERE %I = $1',
            _targetIDColumnName, _enteredByColumnName,
            _targetTableSchema, _targetTableName,
            _targetIDColumnName);

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

        _entryDateFilterSqlWithValues := format(
                            '%I between ''%s'' And ''%s''',
                             _entryDateColumnName,
                            to_char(_entryDateStart, 'yyyy-mm-dd hh24:mi:ss'),
                            to_char(_entryDateEnd,   'yyyy-mm-dd hh24:mi:ss'));

        _entryDateFilterSqlWithVariables := format(
                            '%I between $2 And $3',
                             _entryDateColumnName);

        If _previewSql <> 0 Then
            _s := _s || ' AND ' || _entryDateFilterSqlWithValues;
        Else
            _s := _s || ' AND ' || _entryDateFilterSqlWithVariables;
        End If;

        _entryDescription := _entryDescription || ' with ' || _entryDateFilterSqlWithValues;
    End If;

    If _previewSql <> 0 Then
        -- Show the SQL both with the dollar signs, and with values
        RAISE INFO '%;', _s;
        RAISE INFO '%;', regexp_replace(_s, '\$1', _targetID::text);

        _enteredBy := session_user || '_simulated';
        _targetIDMatch := _targetID;
    Else
        EXECUTE _s INTO _lookupResults USING _targetID, _entryDateStart, _entryDateEnd;
        _enteredBy := _lookupResults.entered_by;
        _targetIDMatch := _lookupResults.target_id_match;
    End If;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _previewSql = 0 AND (_myRowCount <= 0 Or _targetIDMatch <> _targetID) Then
        _message := 'Match not found for ' || _entryDescription;
        Return;
    End If;

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

    If char_length(Coalesce(_enteredByNew, '')) = 0 Then
        _message := 'Match not found; unable to continue';
    End If;

    If _infoOnly = 0 Then

        _s := format(
                'UPDATE %I.%I '
                'SET %I = $4 '
                'WHERE %I = $1',
                _targetTableSchema, _targetTableName,
                _enteredByColumnName,
                _targetIDColumnName);

        If char_length(_entryDateFilterSqlWithVariables) > 0 Then
            If _previewSql <> 0 Then
                _s := _s || ' AND ' || _entryDateFilterSqlWithValues;
            Else
                _s := _s || ' AND ' || _entryDateFilterSqlWithVariables;
            End If;
        End If;

        If _previewSql <> 0 Then
            -- Show the SQL both with the dollar signs, and with values
            RAISE INFO '%;', _s;
            _s := regexp_replace(_s, '\$1', _targetID::text);
            _s := regexp_replace(_s, '\$4', '''' || _enteredByNew || '''');
            RAISE INFO '%;', _s;
        Else
            EXECUTE _s USING _targetID, _entryDateStart, _entryDateEnd, _enteredByNew;
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
                'FROM %I.%I '
                'WHERE %I = $1',
                _targetTableSchema, _targetTableName,
                _targetIDColumnName);

        If char_length(_entryDateFilterSqlWithVariables) > 0 Then
            If _previewSql <> 0 Then
                _s := _s || ' AND ' || _entryDateFilterSqlWithValues;
            Else
                _s := _s || ' AND ' || _entryDateFilterSqlWithVariables;
            End If;
        End If;

        If _previewSql <> 0 Then
            -- Show the SQL both with the dollar signs, and with values
            RAISE INFO '%;', _s;
            RAISE INFO '%;', regexp_replace(_s, '\$1', _targetID::text);
        Else
            Execute _s USING _targetID, _entryDateStart, _entryDateEnd;
        End If;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        _message := 'Would update ' || _entryDescription || ' to indicate "' || _enteredByNew || '"';
    End If;

END
$_$;


ALTER PROCEDURE public.alter_entered_by_user(IN _targettableschema text, IN _targettablename text, IN _targetidcolumnname text, IN _targetid integer, IN _newuser text, IN _applytimefilter integer, IN _entrytimewindowseconds integer, IN _entrydatecolumnname text, IN _enteredbycolumnname text, INOUT _message text, IN _infoonly integer, IN _previewsql integer) OWNER TO d3l243;

--
-- Name: PROCEDURE alter_entered_by_user(IN _targettableschema text, IN _targettablename text, IN _targetidcolumnname text, IN _targetid integer, IN _newuser text, IN _applytimefilter integer, IN _entrytimewindowseconds integer, IN _entrydatecolumnname text, IN _enteredbycolumnname text, INOUT _message text, IN _infoonly integer, IN _previewsql integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.alter_entered_by_user(IN _targettableschema text, IN _targettablename text, IN _targetidcolumnname text, IN _targetid integer, IN _newuser text, IN _applytimefilter integer, IN _entrytimewindowseconds integer, IN _entrydatecolumnname text, IN _enteredbycolumnname text, INOUT _message text, IN _infoonly integer, IN _previewsql integer) IS 'AlterEnteredByUser';

