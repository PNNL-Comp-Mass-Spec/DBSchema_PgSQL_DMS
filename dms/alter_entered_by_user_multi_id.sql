--
-- Name: alter_entered_by_user_multi_id(text, text, text, text, integer, integer, text, text, text, integer, integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.alter_entered_by_user_multi_id(IN _targettableschema text, IN _targettablename text, IN _targetidcolumnname text, IN _newuser text, IN _applytimefilter integer DEFAULT 1, IN _entrytimewindowseconds integer DEFAULT 15, IN _entrydatecolumnname text DEFAULT 'entered'::text, IN _enteredbycolumnname text DEFAULT 'entered_by'::text, INOUT _message text DEFAULT ''::text, IN _infoonly integer DEFAULT 0, IN _previewsql integer DEFAULT 0)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Calls AlterEnteredByUser for each entry in temporary table Tmp_ID_Update_List
**
**      The calling procedure must create and populate the temporary table:
**        CREATE TEMP TABLE Tmp_ID_Update_List (TargetID int NOT NULL);
**
**      Increased performance can be obtained by adding an index to the table;
**      thus it is advisable that the calling procedure also create this index:
**        CREATE INDEX IX_Tmp_ID_Update_List ON Tmp_ID_Update_List (TargetID);
**
**  Arguments:
**    _targetTableSchema        Schema of the table to update; if empty or null, assumes "public"
**    _targetTableName          Table to update
**    _targetIDColumnName       ID column name
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
**  Date:   03/28/2008 mem - Initial version (Ticket: #644)
**          05/23/2008 mem - Expanded @EntryDescription to varchar(512)
**          01/26/2020 mem - Ported to PostgreSQL
**          01/28/2020 mem - Add argument _targetTableSchema
**                         - Remove exception handler and remove argument _returnCode
**          10/20/2022 mem - Rename temporary table
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _entryDateStart timestamp;
    _entryDateEnd timestamp;
    _entryIndex int;
    _matchIndex int;
    _enteredBy text;
    _targetID int;
    _enteredByNew text := '';
    _currentTime timestamp := CURRENT_TIMESTAMP;
    _countUpdated int;
    _startTime timestamp;
    _entryTimeWindowSecondsCurrent int;
    _elapsedSeconds int;
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

    If _targetTableName Is Null Or _targetIDColumnName Is Null Then
        _message := '_targetTableName and _targetIDColumnName must be defined; unable to continue';
        RAISE EXCEPTION '%', _message;
    End If;

    If char_length(_newUser) = 0 Then
        _message := '_newUser is empty; unable to continue';
        RAISE EXCEPTION '%', _message;
    End If;

    -- Make sure Tmp_ID_Update_List is not empty

    If Not Exists (Select * From Tmp_ID_Update_List) Then
        _message := 'Tmp_ID_Update_List is empty; nothing to do';
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
    -- Parse the values in Tmp_ID_Update_List
    -- Call AlterEnteredByUser for each
    ------------------------------------------------

    _countUpdated := 0;

    FOR _targetID IN
        SELECT TargetID
        FROM Tmp_ID_Update_List
        ORDER BY TargetID
    LOOP
        Call AlterEnteredByUser(
                            _targetTableSchema,
                            _targetTableName,
                            _targetIDColumnName,
                            _targetID,
                            _newUser,
                            _applyTimeFilter,
                            _entryTimeWindowSecondsCurrent,
                            _entryDateColumnName,
                            _enteredByColumnName,
                            _message,
                            _infoOnly,
                            _previewSql
                            );

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


ALTER PROCEDURE public.alter_entered_by_user_multi_id(IN _targettableschema text, IN _targettablename text, IN _targetidcolumnname text, IN _newuser text, IN _applytimefilter integer, IN _entrytimewindowseconds integer, IN _entrydatecolumnname text, IN _enteredbycolumnname text, INOUT _message text, IN _infoonly integer, IN _previewsql integer) OWNER TO d3l243;

