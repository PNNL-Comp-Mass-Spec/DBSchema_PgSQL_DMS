--
-- Name: altereventlogentryusermultiid(integer, integer, text, integer, integer, text, text, integer); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE PROCEDURE mc.altereventlogentryusermultiid(_targettype integer, _targetstate integer, _newuser text, _applytimefilter integer DEFAULT 1, _entrytimewindowseconds integer DEFAULT 15, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, _infoonly integer DEFAULT 0)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Calls AlterEventLogEntryUser for each entry in temporary table TmpIDUpdateList
**
**      The calling procedure must create and populate the temporary table:
**        CREATE TEMP TABLE TmpIDUpdateList (TargetID int NOT NULL);
**
**      Increased performance can be obtained by adding an index to the table;
**      thus it is advisable that the calling procedure also create this index:
**        CREATE INDEX IX_TmpIDUpdateList ON TmpIDUpdateList (TargetID);
**
**  Arguments:
**    _targetType               Event type; 1=Manager Enable/Disable
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

    _newUser := Coalesce(_newUser, '');
    _applyTimeFilter := Coalesce(_applyTimeFilter, 0);
    _entryTimeWindowSeconds := Coalesce(_entryTimeWindowSeconds, 15);
    _message := '';
    _returnCode := '';
    _infoOnly := Coalesce(_infoOnly, 0);

    If _targetType Is Null Or _targetState Is Null Then
        _message := '_targetType and _targetState must be defined; unable to continue';
        _returnCode := 'U5201';
        Return;
    End If;

    If char_length(_newUser) = 0 Then
        _message := '_newUser is empty; unable to continue';
        _returnCode := 'U5202';
        Return;
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
    -- Determine the minimum value in TmpIDUpdateList
    ------------------------------------------------

    SELECT Min(TargetID)-1 INTO _targetID
    FROM TmpIDUpdateList;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    _targetID := Coalesce(_targetID, -1);

    ------------------------------------------------
    -- Parse the values in TmpIDUpdateList
    -- Call AlterEventLogEntryUser for each
    ------------------------------------------------

    _countUpdated := 0;
    _continue := 1;

    While _continue = 1 Loop
        SELECT TargetID INTO _targetID
        FROM TmpIDUpdateList
        WHERE TargetID > _targetID
        ORDER BY TargetID
        LIMIT 1;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        IF NOT FOUND THEN
            _continue := 0;
        Else
            Call AlterEventLogEntryUser(
                                _targetType,
                                _targetID,
                                _targetState,
                                _newUser,
                                _applyTimeFilter,
                                _entryTimeWindowSeconds,
                                _message,
                                _returnCode,
                                _infoOnly);

            If char_length(Coalesce(_returnCode, '')) > 0 And _returnCode <> '00000' Then
                Return;
            End If;

            _countUpdated := _countUpdated + 1;
            If _countUpdated % 5 = 0 Then
                _elapsedSeconds := extract(epoch FROM (current_timestamp - _startTime));

                If _elapsedSeconds * 2 > _entryTimeWindowSecondsCurrent Then
                    _entryTimeWindowSecondsCurrent := _elapsedSeconds * 4;
                End If;
            End If;
        End If;
    End Loop;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := 'Error calling AlterEventLogEntryUser: ' || _exceptionMessage;
    _returnCode := _sqlstate;

    -- Future: call PostLogEntry 'Error', _message, 'AlterEventLogEntryUserMultiID'
    INSERT INTO t_log_entries (posted_by, type, message)
    VALUES ('AlterEventLogEntryUserMultiID', 'Error', _message);

END
$$;


ALTER PROCEDURE mc.altereventlogentryusermultiid(_targettype integer, _targetstate integer, _newuser text, _applytimefilter integer, _entrytimewindowseconds integer, INOUT _message text, INOUT _returncode text, _infoonly integer) OWNER TO d3l243;

--
-- Name: PROCEDURE altereventlogentryusermultiid(_targettype integer, _targetstate integer, _newuser text, _applytimefilter integer, _entrytimewindowseconds integer, INOUT _message text, INOUT _returncode text, _infoonly integer); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.altereventlogentryusermultiid(_targettype integer, _targetstate integer, _newuser text, _applytimefilter integer, _entrytimewindowseconds integer, INOUT _message text, INOUT _returncode text, _infoonly integer) IS 'AlterEventLogEntryUserMultiID';

