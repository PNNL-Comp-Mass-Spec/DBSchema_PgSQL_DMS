--
-- Name: alter_event_log_entry_user(text, integer, integer, integer, text, integer, integer, text, integer, integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.alter_event_log_entry_user(IN _eventlogschema text, IN _targettype integer, IN _targetid integer, IN _targetstate integer, IN _newuser text, IN _applytimefilter integer DEFAULT 1, IN _entrytimewindowseconds integer DEFAULT 15, INOUT _message text DEFAULT ''::text, IN _infoonly integer DEFAULT 0, IN _previewsql integer DEFAULT 0)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Updates the user associated with a given event log entry to be _newUser
**
**  Arguments:
**    _eventLogSchema           Schema of the t_event_log table to update; if empty or null, assumes "public"
**    _targetType               Event type; 1=Manager Enable/Disable
**    _targetID                 ID of the entry to update
**    _targetState              Logged state value to match
**    _newUser                  New username to add to the entered_by field
**    _applyTimeFilter          If 1, filters by the current date and time; if 0, looks for the most recent matching entry
**    _entryTimeWindowSeconds   Only used if _applyTimeFilter = 1
**    _message                  Warning or status message
**    _infoOnly                 If 1, preview updates
**    _previewSql               If 1, show the SQL that would be used
**
**  Auth:   mem
**  Date:   02/29/2008 mem - Initial version (Ticket: #644)
**          05/23/2008 mem - Expanded @EntryDescription to varchar(512)
**          03/30/2009 mem - Ported to the Manager Control DB
**          01/26/2020 mem - Ported to PostgreSQL
**          01/28/2020 mem - Add arguments _eventLogSchema and _previewsql
**                         - Remove exception handler and remove argument _returnCode
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _entryDateStart timestamp;
    _entryDateEnd timestamp;
    _entryDescription text := '';
    _eventID int;
    _targetIdMatched int;
    _matchIndex int;
    _enteredBy text;
    _enteredByNew text := '';
    _currentTime timestamp := CURRENT_TIMESTAMP;
    _s text;
    _entryDateFilterSqlWithVariables text := '';
    _entryDateFilterSqlWithValues text := '';
    _dateFilterSql text := '';
    _lookupResults record;
    _previewData record;
    _infoHead text;
    _infoData text;
BEGIN

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _eventLogSchema := COALESCE(_eventLogSchema, '');
    If (char_length(_eventLogSchema) = 0) Then
        _eventLogSchema := 'public';
    End If;

    _newUser := Coalesce(_newUser, '');
    _applyTimeFilter := Coalesce(_applyTimeFilter, 0);
    _entryTimeWindowSeconds := Coalesce(_entryTimeWindowSeconds, 15);
    _message := '';
    _infoOnly := Coalesce(_infoOnly, 0);
    _previewsql := Coalesce(_previewSql, 0);

    If _targetType Is Null Or _targetID Is Null Or _targetState Is Null Then
        _message := '_targetType and _targetID and _targetState must be defined; unable to continue';
        RAISE EXCEPTION '%', _message;
    End If;

    If char_length(_newUser) = 0 Then
        _message := '_newUser is empty; unable to continue';
        RAISE EXCEPTION '%', _message;
    End If;

    _entryDescription := 'ID ' || _targetID::text || ' (type ' || _targetType::text || ') with state ' || _targetState::text;
    If _applyTimeFilter <> 0 And Coalesce(_entryTimeWindowSeconds, 0) >= 1 Then
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

        _entryDateFilterSqlWithValues := format(' AND entered BETWEEN ''%s'' AND ''%s''',
                                        to_char(_entryDateStart, 'yyyy-mm-dd hh24:mi:ss'),
                                        to_char(_entryDateEnd,   'yyyy-mm-dd hh24:mi:ss'));

        _entryDateFilterSqlWithVariables := ' AND entered BETWEEN $4 AND $5';

        If _previewSql <> 0 Then
            _dateFilterSql :=  _entryDateFilterSqlWithValues;
        Else
            _dateFilterSql :=  _entryDateFilterSqlWithVariables;
        End If;

        _entryDescription := _entryDescription ||
                                ' and Entry Time between ' ||
                                to_char(_entryDateStart, 'yyyy-mm-dd hh24:mi:ss') || ' and ' ||
                                to_char(_entryDateEnd,   'yyyy-mm-dd hh24:mi:ss');
    Else
        _dateFilterSql := '';
    End If;

    _s := format(
            'SELECT EL.event_id, EL.entered_by, EL.target_id '
            'FROM %1$I.t_event_log EL INNER JOIN '
                   ' (SELECT MAX(event_id) AS event_id '
                   '  FROM %1$I.t_event_log '
                   '  WHERE target_type = $1 AND '
                   '        target_id = $2 AND '
                   '        target_state = $3'
                   '        %s'
                   ' ) LookupQ ON EL.event_id = LookupQ.event_id',
            _eventLogSchema,
            _dateFilterSql);

    If _previewSql <> 0 Then
         -- Show the SQL both with the dollar signs, and with values
        RAISE INFO '%;', _s;
        _s := regexp_replace(_s, '\$1', _targetType::text);
        _s := regexp_replace(_s, '\$2', _targetID::text);
        _s := regexp_replace(_s, '\$3', _targetState::text);
        RAISE INFO '%;', _s;

        _eventID   := 0;
        _enteredBy := session_user || '_simulated';
        _targetIdMatched := _targetId;
    Else
        EXECUTE _s INTO _lookupResults USING _targetType, _targetID, _targetState, _entryDateStart, _entryDateEnd;
        _eventID   := _lookupResults.event_id;
        _enteredBy := _lookupResults.entered_by;
        _targetIdMatched := _lookupResults.target_id;
    End If;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _previewSql = 0 AND (_myRowCount <= 0 Or _targetIdMatched <> _targetID) Then
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
        RETURN;
    End If;

    If _infoOnly = 0 Then
        _s := format(
                        'UPDATE %I.t_event_log '
                        'SET entered_by = $2 '
                        'WHERE event_id = $1',
                        _eventLogSchema,
                        _enteredByNew);

        If _previewSql <> 0 Then
             -- Show the SQL both with the dollar signs, and with values
            RAISE INFO '%;', _s;
            _s := regexp_replace(_s, '\$1', _eventID::text);
            _s := regexp_replace(_s, '\$2', _enteredByNew);
            RAISE INFO '%;', _s;

            _message := 'Would update ' || _entryDescription || ' to indicate "' || _enteredByNew || '"';
        Else
            EXECUTE _s USING _eventID, _enteredByNew;
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            _message := 'Updated ' || _entryDescription || ' to indicate "' || _enteredByNew || '"';
        End If;

        RETURN;
    End If;

    _s := format(
            'SELECT event_id, target_type, target_id, target_state,'
            '       prev_target_state, entered,'
            '       entered_by AS Entered_By_Old,'
            '       $2 AS Entered_By_New '
            'FROM %I.t_event_log '
            'WHERE event_id = $1',
            _eventLogSchema);

    EXECUTE _s INTO _previewData USING _eventID, _enteredByNew;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    _infoHead := format('%-10s %-12s %-10s %-12s %-18s %-20s %-20s %-20s',
                            'event_id',
                            'target_type',
                            'target_id',
                            'target_state',
                            'prev_target_state',
                            'entered',
                            'entered_by_old',
                            'entered_by_new'
                        );

    _infoData := format('%-10s %-12s %-10s %-12s %-18s %-20s %-20s %-20s',
                            _previewData.event_id,
                            _previewData.target_type,
                            _previewData.target_id,
                            _previewData.target_state,
                            _previewData.prev_target_state,
                            to_char(_previewData.entered, 'yyyy-mm-dd hh24:mi:ss'),
                            _previewData.Entered_By_Old,
                            _previewData.Entered_By_New
                        );

    RAISE INFO '%', _infoHead;
    RAISE INFO '%', _infoData;

    _message := 'Would update ' || _entryDescription || ' to indicate "' || _enteredByNew || '"';

END
$_$;


ALTER PROCEDURE public.alter_event_log_entry_user(IN _eventlogschema text, IN _targettype integer, IN _targetid integer, IN _targetstate integer, IN _newuser text, IN _applytimefilter integer, IN _entrytimewindowseconds integer, INOUT _message text, IN _infoonly integer, IN _previewsql integer) OWNER TO d3l243;

--
-- Name: PROCEDURE alter_event_log_entry_user(IN _eventlogschema text, IN _targettype integer, IN _targetid integer, IN _targetstate integer, IN _newuser text, IN _applytimefilter integer, IN _entrytimewindowseconds integer, INOUT _message text, IN _infoonly integer, IN _previewsql integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.alter_event_log_entry_user(IN _eventlogschema text, IN _targettype integer, IN _targetid integer, IN _targetstate integer, IN _newuser text, IN _applytimefilter integer, IN _entrytimewindowseconds integer, INOUT _message text, IN _infoonly integer, IN _previewsql integer) IS 'AlterEventLogEntryUser';

