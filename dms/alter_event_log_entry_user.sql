--
-- Name: alter_event_log_entry_user(text, integer, integer, integer, text, boolean, integer, text, boolean, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.alter_event_log_entry_user(IN _eventlogschema text, IN _targettype integer, IN _targetid integer, IN _targetstate integer, IN _newuser text, IN _applytimefilter boolean DEFAULT true, IN _entrytimewindowseconds integer DEFAULT 15, INOUT _message text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, IN _previewsql boolean DEFAULT false)
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
**    _applyTimeFilter          When true, filters by the current date and time; when false, looks for the most recent matching entry
**    _entryTimeWindowSeconds   Only used if _applyTimeFilter is true
**    _message                  Warning or status message
**    _infoOnly                 When true, preview updates
**    _previewSql               When true, show the SQL that would be used
**
**  Auth:   mem
**  Date:   02/29/2008 mem - Initial version (Ticket: #644)
**          05/23/2008 mem - Expanded _EntryDescription to varchar(512)
**          03/30/2009 mem - Ported to the Manager Control DB
**          01/26/2020 mem - Ported to PostgreSQL
**          01/28/2020 mem - Add arguments _eventLogSchema and _previewSql
**                         - Remove exception handler and remove argument _returnCode
**          04/16/2022 mem - Rename procedure
**          11/10/2022 mem - Change _applyTimeFilter, _infoOnly, and _previewSql to booleans
**          01/24/2023 mem - Update whitespace
**          05/12/2023 mem - Rename variables
**          05/18/2023 mem - Remove implicit string concatenation
**          05/31/2023 mem - Use format() for string concatenation
**                         - Add back implicit string concatenation
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/11/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**
*****************************************************/
DECLARE
    _updateCount int;
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
    _message := '';

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _eventLogSchema := Trim(Coalesce(_eventLogSchema, ''));

    If (char_length(_eventLogSchema) = 0) Then
        _eventLogSchema := 'public';
    End If;

    _newUser                := Trim(Coalesce(_newUser, ''));
    _applyTimeFilter        := Coalesce(_applyTimeFilter, false);
    _entryTimeWindowSeconds := Coalesce(_entryTimeWindowSeconds, 15);
    _infoOnly               := Coalesce(_infoOnly, false);
    _previewSql             := Coalesce(_previewSql, false);

    If _targetType Is Null Or _targetID Is Null Or _targetState Is Null Then
        _message := '_targetType and _targetID and _targetState must be defined; unable to continue';
        RAISE EXCEPTION '%', _message;
    End If;

    If char_length(_newUser) = 0 Then
        _message := '_newUser is empty; unable to continue';
        RAISE EXCEPTION '%', _message;
    End If;

    _entryDescription := format('ID %s (type %s) with state %s',
                                _targetID, _targetType, _targetState);

    If _applyTimeFilter And Coalesce(_entryTimeWindowSeconds, 0) >= 1 Then
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

        _entryDateFilterSqlWithValues := format(' AND entered BETWEEN ''%s'' AND ''%s''',
                                        to_char(_entryDateStart, 'yyyy-mm-dd hh24:mi:ss'),
                                        to_char(_entryDateEnd,   'yyyy-mm-dd hh24:mi:ss'));

        _entryDateFilterSqlWithVariables := ' AND entered BETWEEN $4 AND $5';

        If _previewSql Then
            _dateFilterSql := _entryDateFilterSqlWithValues;
        Else
            _dateFilterSql := _entryDateFilterSqlWithVariables;
        End If;

        _entryDescription := format('%s and Entry Time between %s and %s',
                                    _entryDescription,
                                    to_char(_entryDateStart, 'yyyy-mm-dd hh24:mi:ss'),
                                    to_char(_entryDateEnd,   'yyyy-mm-dd hh24:mi:ss'));
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

    If _previewSql Then
         -- Show the SQL both with the dollar signs, and with values
        RAISE INFO '%;', _s;
        _s := regexp_replace(_s, '\$1', _targetType::text);
        _s := regexp_replace(_s, '\$2', _targetID::text);
        _s := regexp_replace(_s, '\$3', _targetState::text);
        RAISE INFO '%;', _s;

        _eventID   := 0;
        _enteredBy := format('%s_simulated', session_user);
        _targetIdMatched := _targetId;
    Else
        EXECUTE _s
        INTO _lookupResults
        USING _targetType, _targetID, _targetState, _entryDateStart, _entryDateEnd;

        _eventID   := _lookupResults.event_id;
        _enteredBy := _lookupResults.entered_by;
        _targetIdMatched := _lookupResults.target_id;
    End If;
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If Not _previewSql And (_updateCount = 0 Or _targetIdMatched <> _targetID) Then
        _message := format('Match not found for %s', _entryDescription);
        RETURN;
    End If;

    -- Confirm that _enteredBy doesn't already contain _newUser
    -- If it does, there's no need to update it

    _matchIndex := Position(_newUser In _enteredBy);
    If _matchIndex > 0 Then
        _message := format('Entry %s is already attributed to %s: "%s"',
                            _entryDescription, _newUser, _enteredBy);
        RETURN;
    End If;

    -- Look for a semicolon in _enteredBy

    _matchIndex := Position(';' In _enteredBy);

    If _matchIndex > 0 Then
        _enteredByNew := format('%s (via %s)%s',
                                _newUser,
                                Substring(_enteredBy, 1, _matchIndex-1),
                                Substring(_enteredBy, _matchIndex, char_length(_enteredBy)));
    Else
        _enteredByNew := format('%s (via %s)', _newUser, _enteredBy);
    End If;

    If char_length(Coalesce(_enteredByNew, '')) = 0 Then
        _message := 'Match not found; unable to continue';
        RETURN;
    End If;

    If Not _infoOnly Then
        _s := format( 'UPDATE %I.t_event_log '
                      'SET entered_by = $2 '
                      'WHERE event_id = $1',
                      _eventLogSchema,
                      _enteredByNew);

        If _previewSql Then
             -- Show the SQL both with the dollar signs, and with values
            RAISE INFO '%;', _s;
            _s := regexp_replace(_s, '\$1', _eventID::text);
            _s := regexp_replace(_s, '\$2', _enteredByNew);
            RAISE INFO '%;', _s;

            _message := format('Would update %s to indicate "%s"', _entryDescription, _enteredByNew);
        Else
            EXECUTE _s
            USING _eventID, _enteredByNew;

            _message := format('Updated %s to indicate "%s"', _entryDescription, _enteredByNew);
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

    EXECUTE _s
    INTO _previewData
    USING _eventID, _enteredByNew;

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

    _message := format('Would update %s to indicate "%s"', _entryDescription, _enteredByNew);

END
$_$;


ALTER PROCEDURE public.alter_event_log_entry_user(IN _eventlogschema text, IN _targettype integer, IN _targetid integer, IN _targetstate integer, IN _newuser text, IN _applytimefilter boolean, IN _entrytimewindowseconds integer, INOUT _message text, IN _infoonly boolean, IN _previewsql boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE alter_event_log_entry_user(IN _eventlogschema text, IN _targettype integer, IN _targetid integer, IN _targetstate integer, IN _newuser text, IN _applytimefilter boolean, IN _entrytimewindowseconds integer, INOUT _message text, IN _infoonly boolean, IN _previewsql boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.alter_event_log_entry_user(IN _eventlogschema text, IN _targettype integer, IN _targetid integer, IN _targetstate integer, IN _newuser text, IN _applytimefilter boolean, IN _entrytimewindowseconds integer, INOUT _message text, IN _infoonly boolean, IN _previewsql boolean) IS 'AlterEventLogEntryUser';

