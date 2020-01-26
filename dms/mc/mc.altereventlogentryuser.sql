--
-- Name: altereventlogentryuser(integer, integer, integer, text, integer, integer, text, text, integer); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE PROCEDURE mc.altereventlogentryuser(_targettype integer, _targetid integer, _targetstate integer, _newuser text, _applytimefilter integer DEFAULT 1, _entrytimewindowseconds integer DEFAULT 15, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, _infoonly integer DEFAULT 0)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the user associated with a given event log entry to be _newUser
**
**  Arguments:
**    _targetType               Event type; 1=Manager Enable/Disable
**    _targetID                 ID of the entry to update
**    _targetState              Logged state value to match
**    _newUser                  New username to add to the entered_by field
**    _applyTimeFilter          If 1, filters by the current date and time; if 0, looks for the most recent matching entry
**    _entryTimeWindowSeconds   Only used if _applyTimeFilter = 1
**    _message                  Warning or status message
**    _returnCode               Empty or '00000' if no error, otherwise, a SQLSTATE code. User-codes start with 'U'
**    _infoOnly                 If 1, preview updates
**
**  Auth:   mem
**  Date:   02/29/2008 mem - Initial version (Ticket: #644)
**          05/23/2008 mem - Expanded @EntryDescription to varchar(512)
**          03/30/2009 mem - Ported to the Manager Control DB
**          01/26/2020 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _entryDateStart timestamp;
    _entryDateEnd timestamp;
    _entryDescription text := '';
    _eventID int;
    _matchIndex int;
    _enteredBy text;
    _enteredByNew text := '';
    _currentTime timestamp := CURRENT_TIMESTAMP;
    _lookupResults record;
    _previewData record;
    _infoHead text;
    _infoData text;
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

    If _targetType Is Null Or _targetID Is Null Or _targetState Is Null Then
        _message := '_targetType and _targetID and _targetState must be defined; unable to continue';
        _returnCode := 'U5201';
        Return;
    End If;

    If char_length(_newUser) = 0 Then
        _message := '_newUser is empty; unable to continue';
        _returnCode := 'U5202';
        Return;
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

        SELECT EL.event_id, EL.entered_by INTO _lookupResults
        FROM mc.t_event_log EL INNER JOIN
                (SELECT MAX(event_id) AS event_id
                 FROM mc.t_event_log
                 WHERE target_type = _targetType AND
                       target_id = _targetID AND
                       target_state = _targetState AND
                       entered Between _entryDateStart And _entryDateEnd
                ) LookupQ ON EL.event_id = LookupQ.event_id;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        _eventID   := _lookupResults.event_id;
        _enteredBy := _lookupResults.entered_by;

        _entryDescription := _entryDescription ||
                                ' and Entry Time between ' ||
                                to_char(_entryDateStart, 'yyyy-mm-dd hh24:mi:ss') || ' and ' ||
                                to_char(_entryDateEnd,   'yyyy-mm-dd hh24:mi:ss');
    Else
        ------------------------------------------------
        -- Do not filter by time
        ------------------------------------------------
        --
        SELECT EL.event_id, EL.entered_by INTO _lookupResults
        FROM mc.t_event_log EL INNER JOIN
                (SELECT MAX(event_id) AS event_id
                 FROM mc.t_event_log
                 WHERE target_type = _targetType AND
                       target_id = _targetID AND
                       target_state = _targetState
                ) LookupQ ON EL.event_id = LookupQ.event_id;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        _eventID   := _lookupResults.event_id;
        _enteredBy := _lookupResults.entered_by;

    End If;

    If _myRowCount <= 0 Then
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

    If char_length(Coalesce(_enteredByNew, '')) > 0 Then

        If _infoOnly = 0 Then
            UPDATE mc.t_event_log
            SET entered_by = _enteredByNew
            WHERE event_id = _eventID;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            _message := 'Updated ' || _entryDescription || ' to indicate "' || _enteredByNew || '"';
        Else
            SELECT event_id, target_type, target_id, target_state,
                   prev_target_state, entered,
                   entered_by AS Entered_By_Old,
                   _enteredByNew AS Entered_By_New INTO _previewData
            FROM mc.t_event_log
            WHERE event_id = _eventID;
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
        End If;

    Else
        _message := 'Match not found; unable to continue';
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


ALTER PROCEDURE mc.altereventlogentryuser(_targettype integer, _targetid integer, _targetstate integer, _newuser text, _applytimefilter integer, _entrytimewindowseconds integer, INOUT _message text, INOUT _returncode text, _infoonly integer) OWNER TO d3l243;

--
-- Name: PROCEDURE altereventlogentryuser(_targettype integer, _targetid integer, _targetstate integer, _newuser text, _applytimefilter integer, _entrytimewindowseconds integer, INOUT _message text, INOUT _returncode text, _infoonly integer); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.altereventlogentryuser(_targettype integer, _targetid integer, _targetstate integer, _newuser text, _applytimefilter integer, _entrytimewindowseconds integer, INOUT _message text, INOUT _returncode text, _infoonly integer) IS 'AlterEventLogEntryUser';

