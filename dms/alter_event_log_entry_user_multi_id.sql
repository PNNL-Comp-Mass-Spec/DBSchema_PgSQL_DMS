--
-- Name: alter_event_log_entry_user_multi_id(text, integer, integer, text, boolean, integer, text, boolean, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.alter_event_log_entry_user_multi_id(IN _eventlogschema text, IN _targettype integer, IN _targetstate integer, IN _newuser text, IN _applytimefilter boolean DEFAULT true, IN _entrytimewindowseconds integer DEFAULT 15, INOUT _message text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, IN _previewsql boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Call alter_event_log_entry_user for each entry in temporary table Tmp_ID_Update_List
**      Update the user associated with the given event log entries to be _newUser
**
**      The calling procedure must create and populate the temporary table:
**        CREATE TEMP TABLE Tmp_ID_Update_List (TargetID int NOT NULL);
**
**      Increased performance can be obtained by adding an index to the table;
**      thus it is advisable that the calling procedure also create this index:
**        CREATE UNIQUE INDEX IX_Tmp_ID_Update_List ON Tmp_ID_Update_List (TargetID);
**
**  Arguments:
**    _eventLogSchema           Schema of the t_event_log table to update; if empty or null, assumes "public"
**    _targetType               Target type; 1=Campaign, 2=Biomaterial, 3=Experiment, 4=Dataset, 5=Analysis Job, etc.; see tables public.t_event_target and mc.t_event_target
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
**          05/23/2008 mem - Expanded @EntryDescription to varchar(512)
**          03/30/2009 mem - Ported to the Manager Control DB
**          01/26/2020 mem - Ported to PostgreSQL
**          01/28/2020 mem - Add arguments _eventLogSchema and _previewSql
**                         - Remove exception handler and remove argument _returnCode
**          10/20/2022 mem - Rename temporary table
**          11/09/2022 mem - Use new procedure name
**          11/10/2022 mem - Change _applyTimeFilter, _infoOnly, and _previewSql to booleans
**                         - Remove unused variables and use clock_timestamp()
**          05/22/2023 mem - Capitalize reserved word
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**
*****************************************************/
DECLARE
    _targetID int;
    _countUpdated int;
    _startTime timestamp;
    _entryTimeWindowSecondsCurrent int;
    _elapsedSeconds int;
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

    If _targetType Is Null Or _targetState Is Null Then
        _message := '_targetType and _targetState must be defined; unable to continue';
        RAISE EXCEPTION '%', _message;
    End If;

    If char_length(_newUser) = 0 Then
        _message := '_newUser is empty; unable to continue';
        RAISE EXCEPTION '%', _message;
    End If;

    -- Make sure Tmp_ID_Update_List is not empty

    If Not Exists (Select * From Tmp_ID_Update_List) Then
        _message := 'Tmp_ID_Update_List is empty; nothing to do';
        RETURN;
    End If;

    ------------------------------------------------
    -- Initialize _entryTimeWindowSecondsCurrent
    --
    -- This variable will be automatically increased
    -- if too much time elapses
    ------------------------------------------------

    _startTime := clock_timestamp();
    _entryTimeWindowSecondsCurrent := _entryTimeWindowSeconds;

    ------------------------------------------------
    -- Parse the values in Tmp_ID_Update_List
    -- Call alter_event_log_entry_user for each
    ------------------------------------------------

    _countUpdated := 0;

    FOR _targetID IN
        SELECT TargetID
        FROM Tmp_ID_Update_List
        ORDER BY TargetID
    LOOP
        CALL public.alter_event_log_entry_user(
                            _eventlogschema,
                            _targetType,
                            _targetID,
                            _targetState,
                            _newUser,
                            _applyTimeFilter,
                            _entryTimeWindowSeconds,
                            _message,
                            _infoOnly,
                            _previewSql);

        _countUpdated := _countUpdated + 1;
        If _countUpdated % 5 = 0 Then
            _elapsedSeconds := extract(epoch FROM (clock_timestamp() - _startTime));

            If _elapsedSeconds * 2 > _entryTimeWindowSecondsCurrent Then
                _entryTimeWindowSecondsCurrent := _elapsedSeconds * 4;
            End If;
        End If;
    END LOOP;

END
$$;


ALTER PROCEDURE public.alter_event_log_entry_user_multi_id(IN _eventlogschema text, IN _targettype integer, IN _targetstate integer, IN _newuser text, IN _applytimefilter boolean, IN _entrytimewindowseconds integer, INOUT _message text, IN _infoonly boolean, IN _previewsql boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE alter_event_log_entry_user_multi_id(IN _eventlogschema text, IN _targettype integer, IN _targetstate integer, IN _newuser text, IN _applytimefilter boolean, IN _entrytimewindowseconds integer, INOUT _message text, IN _infoonly boolean, IN _previewsql boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.alter_event_log_entry_user_multi_id(IN _eventlogschema text, IN _targettype integer, IN _targetstate integer, IN _newuser text, IN _applytimefilter boolean, IN _entrytimewindowseconds integer, INOUT _message text, IN _infoonly boolean, IN _previewsql boolean) IS 'AlterEventLogEntryUserMultiID';

