--
-- Name: altereventlogentryusermultiid(text, integer, integer, text, integer, integer, text, integer, integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE PROCEDURE public.altereventlogentryusermultiid(_eventlogschema text, _targettype integer, _targetstate integer, _newuser text, _applytimefilter integer DEFAULT 1, _entrytimewindowseconds integer DEFAULT 15, INOUT _message text DEFAULT ''::text, _infoonly integer DEFAULT 0, _previewsql integer DEFAULT 0)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Calls AlterEventLogEntryUser for each entry in temporary table TmpIDUpdateList
**      Updates the user associated with the given event log entries to be _newUser
**
**      The calling procedure must create and populate the temporary table:
**        CREATE TEMP TABLE TmpIDUpdateList (TargetID int NOT NULL);
**
**      Increased performance can be obtained by adding an index to the table;
**      thus it is advisable that the calling procedure also create this index:
**        CREATE INDEX IX_TmpIDUpdateList ON TmpIDUpdateList (TargetID);
**
**  Arguments:
**    _eventLogSchema           Schema of the t_event_log table to update; if empty or null, assumes "public"
**    _targetType               Event type; 1=Manager Enable/Disable
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
    _targetID int;
    _countUpdated int;
    _continue int;
    _startTime timestamp;
    _entryTimeWindowSecondsCurrent int;
    _elapsedSeconds int;
    _sqlstate text;
    _exceptionMessage text;
    _exceptionContext text;
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

    If _targetType Is Null Or _targetState Is Null Then
        _message := '_targetType and _targetState must be defined; unable to continue';
        RAISE EXCEPTION '%', _message;
    End If;

    If char_length(_newUser) = 0 Then
        _message := '_newUser is empty; unable to continue';
        RAISE EXCEPTION '%', _message;
    End If;

    -- Make sure TmpIDUpdateList is not empty

    If Not Exists (Select * From TmpIDUpdateList) Then
        _message := 'TmpIDUpdateList is empty; nothing to do';
        Return;
    End If;

    ------------------------------------------------
    -- Initialize _entryTimeWindowSecondsCurrent
    -- This variable will be automatically increased
    --  if too much time elapses
    ------------------------------------------------
    --
    _startTime := CURRENT_TIMESTAMP;
    _entryTimeWindowSecondsCurrent := _entryTimeWindowSeconds;

    ------------------------------------------------
    -- Parse the values in TmpIDUpdateList
    -- Call AlterEventLogEntryUser for each
    ------------------------------------------------

    _countUpdated := 0;

    For _targetID In
        SELECT TargetID
        FROM TmpIDUpdateList
        ORDER BY TargetID
    Loop
        Call AlterEventLogEntryUser(
                            _eventlogschema,
                            _targetType,
                            _targetID,
                            _targetState,
                            _newUser,
                            _applyTimeFilter,
                            _entryTimeWindowSeconds,
                            _message,
                            _infoOnly,
                            _previewsql);

        _countUpdated := _countUpdated + 1;
        If _countUpdated % 5 = 0 Then
            _elapsedSeconds := extract(epoch FROM (current_timestamp - _startTime));

            If _elapsedSeconds * 2 > _entryTimeWindowSecondsCurrent Then
                _entryTimeWindowSecondsCurrent := _elapsedSeconds * 4;
            End If;
        End If;
    End Loop;

END
$$;


ALTER PROCEDURE public.altereventlogentryusermultiid(_eventlogschema text, _targettype integer, _targetstate integer, _newuser text, _applytimefilter integer, _entrytimewindowseconds integer, INOUT _message text, _infoonly integer, _previewsql integer) OWNER TO d3l243;

--
-- Name: PROCEDURE altereventlogentryusermultiid(_eventlogschema text, _targettype integer, _targetstate integer, _newuser text, _applytimefilter integer, _entrytimewindowseconds integer, INOUT _message text, _infoonly integer, _previewsql integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.altereventlogentryusermultiid(_eventlogschema text, _targettype integer, _targetstate integer, _newuser text, _applytimefilter integer, _entrytimewindowseconds integer, INOUT _message text, _infoonly integer, _previewsql integer) IS 'AlterEventLogEntryUserMultiID';

