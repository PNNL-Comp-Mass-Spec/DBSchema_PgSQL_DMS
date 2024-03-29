--
-- Name: alter_entered_by_user(text, text, text, integer, text, boolean, integer, text, text, text, boolean, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.alter_entered_by_user(IN _targettableschema text, IN _targettablename text, IN _targetidcolumnname text, IN _targetid integer, IN _newuser text, IN _applytimefilter boolean DEFAULT true, IN _entrytimewindowseconds integer DEFAULT 15, IN _entrydatecolumnname text DEFAULT 'entered'::text, IN _enteredbycolumnname text DEFAULT 'entered_by'::text, INOUT _message text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, IN _previewsql boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Update the entered_by column for the specified row in the given table to contain _newUser
**
**  Arguments:
**    _targetTableSchema        Schema of the table to update; if empty or null, assumes "public"
**    _targetTableName          Table to update
**    _targetIDColumnName       ID column name
**    _targetID                 ID of the entry to update
**    _newUser                  New username to add to the entered_by field
**    _applyTimeFilter          When true, filters by the current date and time; when false, looks for the most recent matching entry
**    _entryTimeWindowSeconds   Only used if _applyTimeFilter is true
**    _entryDateColumnName      Column name to use when _applyTimeFilter is true
**    _enteredByColumnName      Column name to update the username
**    _message                  Warning or status message
**    _infoOnly                 When true, preview updates
**    _previewSql               When true, show the SQL that would be used
**
**  Auth:   mem
**  Date:   03/25/2008 mem - Initial version (Ticket: #644)
**          05/23/2008 mem - Expanded _EntryDescription to varchar(512)
**          01/25/2020 mem - Ported to PostgreSQL
**          01/28/2020 mem - Add argument _targetTableSchema
**                         - Remove exception handler and remove argument _returnCode
**          04/16/2022 mem - Rename procedure
**          11/10/2022 mem - Change _applyTimeFilter, _infoOnly, and _previewSql to booleans
**          12/12/2022 mem - Whitespace update
**          05/12/2023 mem - Rename variables
**          05/18/2023 mem - Remove implicit string concatenation
**          05/31/2023 mem - Use format() for string concatenation
**                         - Add back implicit string concatenation
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/11/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          12/02/2023 mem - Rename variable
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**
*****************************************************/
DECLARE
    _updateCount int;
    _entryDateStart timestamp;
    _entryDateEnd timestamp;
    _entryDescription text := '';
    _matchPos int;
    _enteredBy text;
    _targetIDMatch int;
    _enteredByNew text := '';
    _currentTime timestamp := CURRENT_TIMESTAMP;
    _s text;
    _entryDateFilterSqlWithVariables text := '';
    _entryDateFilterSqlWithValues text := '';
    _lookupResults record;
BEGIN
    _message := '';

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _targetTableSchema := Trim(Coalesce(_targetTableSchema, ''));

    If _targetTableSchema = '' Then
        _targetTableSchema := 'public';
    End If;

    _newUser                := Trim(Coalesce(_newUser, ''));
    _applyTimeFilter        := Coalesce(_applyTimeFilter, false);
    _entryTimeWindowSeconds := Coalesce(_entryTimeWindowSeconds, 15);
    _infoOnly               := Coalesce(_infoOnly, false);
    _previewSql             := Coalesce(_previewSql, false);

    If _targetTableName Is Null Or _targetIDColumnName Is Null Or _targetID Is Null Then
        _message := '_targetTableName and _targetIDColumnName and _targetID must be defined; unable to continue';
        RAISE EXCEPTION '%', _message;
    End If;

    If _newUser = '' Then
        _message := '_newUser is empty; unable to continue';
        RAISE EXCEPTION '%', _message;
    End If;

    _entryDescription := format('ID %s in table %s (column %s)',
                                _targetID, _targetTableName, _targetIDColumnName);

    _s := format(
            'SELECT %I as target_id_match, %I as entered_by '
            'FROM %I.%I '
            'WHERE %I = $1',
            _targetIDColumnName, _enteredByColumnName,
            _targetTableSchema, _targetTableName,
            _targetIDColumnName);

    If _applyTimeFilter And _entryTimeWindowSeconds >= 1 Then
        ------------------------------------------------
        -- Filter using the current date/time
        ------------------------------------------------

        _entryDateStart := _currentTime - (format('%s seconds', _entryTimeWindowSeconds))::INTERVAL;
        _entryDateEnd   := _currentTime + INTERVAL '1 second';

        If _infoOnly Then
            RAISE INFO 'Filtering on entries dated between % and % (Window = % seconds)',
                to_char(_entryDateStart, 'yyyy-mm-dd hh24:mi:ss'),
                to_char(_entryDateEnd,   'yyyy-mm-dd hh24:mi:ss'),
                _entryTimeWindowSeconds;
        End If;

        _entryDateFilterSqlWithValues := format(
                            '%I BETWEEN ''%s'' And ''%s''',
                            _entryDateColumnName,
                            to_char(_entryDateStart, 'yyyy-mm-dd hh24:mi:ss'),
                            to_char(_entryDateEnd,   'yyyy-mm-dd hh24:mi:ss'));

        _entryDateFilterSqlWithVariables := format(
                            '%I BETWEEN $2 And $3',
                             _entryDateColumnName);

        If _previewSql Then
            _s := format('%s AND %s', _s, _entryDateFilterSqlWithValues);
        Else
            _s := format('%s AND %s', _s, _entryDateFilterSqlWithVariables);
        End If;

        _entryDescription := format('%s with %s', _entryDescription, _entryDateFilterSqlWithValues);
    End If;

    If _previewSql Then
        -- Show the SQL both with the dollar signs, and with values
        RAISE INFO '%;', _s;
        RAISE INFO '%;', regexp_replace(_s, '\$1', _targetID::text);

        _enteredBy := format('%s_simulated', SESSION_USER);
        _targetIDMatch := _targetID;
    Else
        EXECUTE _s
        INTO _lookupResults
        USING _targetID, _entryDateStart, _entryDateEnd;

        _enteredBy := _lookupResults.entered_by;
        _targetIDMatch := _lookupResults.target_id_match;
    End If;
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If Not _previewSql And (_updateCount = 0 Or _targetIDMatch <> _targetID) Then
        _message := format('Match not found for %s', _entryDescription);
        RETURN;
    End If;

    -- Confirm that _enteredBy doesn't already contain _newUser
    -- If it does, there's no need to update it

    _matchPos := Position(_newUser In _enteredBy);

    If _matchPos > 0 Then
        _message := format('Entry %s is already attributed to %s: "%s"',
                            _entryDescription, _newUser, _enteredBy);
        RETURN;
    End If;

    -- Look for a semicolon in _enteredBy
    _matchPos := Position(';' In _enteredBy);

    If _matchPos > 0 Then
        _enteredByNew := format('%s (via %s)%s',
                                _newUser,
                                Substring(_enteredBy, 1, _matchPos - 1),
                                Substring(_enteredBy, _matchPos, char_length(_enteredBy)));
    Else
        _enteredByNew := format('%s (via %s)', _newUser, _enteredBy);
    End If;

    If char_length(Coalesce(_enteredByNew, '')) = 0 Then
        _message := 'Match not found; unable to continue';
    End If;

    If Not _infoOnly Then

        _s := format(
                'UPDATE %I.%I '
                'SET %I = $4 '
                'WHERE %I = $1',
                _targetTableSchema, _targetTableName,
                _enteredByColumnName,
                _targetIDColumnName);

        If _entryDateFilterSqlWithVariables <> '' Then
            If _previewSql Then
                _s := format('%s AND %s', _s, _entryDateFilterSqlWithValues);
            Else
                _s := format('%s AND %s', _s, _entryDateFilterSqlWithVariables);
            End If;
        End If;

        If _previewSql Then
            -- Show the SQL both with the dollar signs, and with values
            RAISE INFO '%;', _s;
            _s := regexp_replace(_s, '\$1', _targetID::text);
            _s := regexp_replace(_s, '\$4', format('''%s''', _enteredByNew));
            RAISE INFO '%;', _s;
        Else
            EXECUTE _s
            USING _targetID, _entryDateStart, _entryDateEnd, _enteredByNew;
        End If;

        If _previewSql Then
            _message := 'SQL previewed for updating';
        Else
            _message := 'Updated';
        End If;

        _message := format('%s %s to indicate "%s"', _message, _entryDescription, _enteredByNew);

    Else
        _s := format(
                'SELECT *, ''%s'' AS Entered_By_New '
                'FROM %I.%I '
                'WHERE %I = $1',
                _enteredByNew,
                _targetTableSchema, _targetTableName,
                _targetIDColumnName);

        If _entryDateFilterSqlWithVariables <> '' Then
            If _previewSql Then
                _s := format('%s AND %s', _s, _entryDateFilterSqlWithValues);
            Else
                _s := format('%s AND %s', _s, _entryDateFilterSqlWithVariables);
            End If;
        End If;

        If _previewSql Then
            -- Show the SQL both with the dollar signs, and with values
            RAISE INFO '%;', _s;
            RAISE INFO '%;', regexp_replace(_s, '\$1', _targetID::text);
        Else
            EXECUTE _s
            USING _targetID, _entryDateStart, _entryDateEnd;
        End If;

        _message := format('Would update %s to indicate "%s"', _entryDescription, _enteredByNew);
    End If;

END
$_$;


ALTER PROCEDURE public.alter_entered_by_user(IN _targettableschema text, IN _targettablename text, IN _targetidcolumnname text, IN _targetid integer, IN _newuser text, IN _applytimefilter boolean, IN _entrytimewindowseconds integer, IN _entrydatecolumnname text, IN _enteredbycolumnname text, INOUT _message text, IN _infoonly boolean, IN _previewsql boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE alter_entered_by_user(IN _targettableschema text, IN _targettablename text, IN _targetidcolumnname text, IN _targetid integer, IN _newuser text, IN _applytimefilter boolean, IN _entrytimewindowseconds integer, IN _entrydatecolumnname text, IN _enteredbycolumnname text, INOUT _message text, IN _infoonly boolean, IN _previewsql boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.alter_entered_by_user(IN _targettableschema text, IN _targettablename text, IN _targetidcolumnname text, IN _targetid integer, IN _newuser text, IN _applytimefilter boolean, IN _entrytimewindowseconds integer, IN _entrydatecolumnname text, IN _enteredbycolumnname text, INOUT _message text, IN _infoonly boolean, IN _previewsql boolean) IS 'AlterEnteredByUser';

