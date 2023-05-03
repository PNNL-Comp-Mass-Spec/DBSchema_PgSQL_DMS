--

CREATE OR REPLACE PROCEDURE pc.verify_update_enabled
(
    _stepName text = 'PMT_Tag_DB_Update',
    _callingFunctionDescription text = 'Unknown',
    _allowPausing int = 0,
    _postLogEntryIfDisabled int = 1,
    _minimumHealthUpdateIntervalSeconds int = 5,
    INOUT _updateEnabled int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Checks whether _stepName is Enabled in MT_Main.dbo.T_Process_Step_Control
**      If it is not Enabled, then sets _updateEnabled to 0
**       and optionally posts a warning message to the log
**      If the step is paused and _allowPausing = 1, then enters an infinite loop,
**       checking for a change in Execution_State every 20 seconds
**      If the step is paused and _allowPausing = 0, then does not pause, but
**       sets _updateEnabled to 0
**
**  Arguments:
**    _allowPausing                         Set to 1 to allow pausing if Execution_State is 2 or 3
**    _minimumHealthUpdateIntervalSeconds   Minimum interval between updating the Last_Query fields
**
**  Auth:   mem
**  Date:   03/10/2006
**          03/11/2006 mem - Now populating the Last_Query fields and added support for pausing
**          03/12/2006 mem - Altered behavior to set _updateEnabled to 0 if _stepName is not in T_Process_Step_Control
**          03/13/2006 mem - Added support for Execution_State 3 (Pause with manual unpause)
**          03/14/2006 mem - Now updating Pause_Length_Minutes in MT_Main.dbo.T_Current_Activity if any pausing occurs and Update_State = 2
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _maximumPauseLengthHours int;
    _sleepTimeSeconds int;
    _sleepTime timestamp;
    _callingDBAndDescription text;
    _executionState int        -- 0 := Disabled, 1 = Enabled, 2 = Paused with auto unpause, 3 = Pause with manual unpause;
    _pauseStartLogged int;
    _lastUpdateTime timestamp;
    _pauseStartTime timestamp;
    _pauseAborted int;
    _pauseLengthMinutes real;
    _pauseLengthMinutesAtStart real;
    _lastCurrentActivityUpdateTime timestamp;
BEGIN
    _message := '';
    _returnCode:= '';
    _minimumHealthUpdateIntervalSeconds := Coalesce(_minimumHealthUpdateIntervalSeconds, 5);

    -- Make sure _callingFunctionDescription is not null, and prepend it with the database name
    _callingFunctionDescription := Coalesce(_callingFunctionDescription, 'Unknown');

    _maximumPauseLengthHours := 48;
    _sleepTimeSeconds := 20;
    _sleepTime := _sleepTimeSeconds/86400.0::timestamp;

    _callingDBAndDescription := DB_Name() || ': ' || _callingFunctionDescription;

    _updateEnabled := 0;
    _pauseStartLogged := 0;
    _pauseAborted := 0;
    _lastUpdateTime := CURRENT_TIMESTAMP-1;

    _pauseLengthMinutes := 0;
    _pauseLengthMinutesAtStart := 0;
    _lastCurrentActivityUpdateTime := _lastUpdateTime;

    _executionState := 2;
    While (_executionState = 2 OR _executionState = 3) AND _myError = 0 Loop
        SELECT Processing_Step_Name INTO _stepName
        FROM MT_Main.dbo.T_Process_Step_Control
        WHERE Processing_Step_Name = _stepName
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount = 0 OR _myError <> 0 Then
        -- <b1>
            -- Error or entry not found in MT_Main.dbo.T_Process_Step_Control
            -- Assume the step is disabled and post an error to the log, but limit to one posting every hour
            If _myError = 0 Then
                _message := 'Processing step ' || _stepName || ' was not found in MT_Main.dbo.T_Process_Step_Control';
                _myError := 20000;
            Else
                _message := 'Error examining state of processing step ' || _stepName || ' in MT_Main.dbo.T_Process_Step_Control';
            End If;

            Call post_log_entry ('Error', _message, 'Verify_Update_Enabled', 'pc', _duplicateEntryHoldoffHours => 1);

            _executionState := 0;
        Else
        -- <b2>
            If (_executionState = 2 OR _executionState = 3) AND _allowPausing = 0 Then
                _executionState := 0;
            End If;

            -- Update the Last_Query information in T_Process_Step_Control
            If (_executionState = 2 OR _executionState = 3) Then
            -- <c1>
                -- Execution is paused
                -- Post a log entry if this is the first loop
                If _pauseStartLogged = 0 Then
                    _message := 'Pausing processing step ' || _stepName || ' (called by ' || _callingFunctionDescription || ')';
                    Call post_log_entry ('Normal', _message, 'Verify_Update_Enabled', 'pc');
                    _message := '';

                    _pauseStartTime := CURRENT_TIMESTAMP;
                    _pauseStartLogged := 1;

                    -- Populate _pauseLengthMinutesAtStart
                    SELECT Pause_Length_Minutes INTO _pauseLengthMinutesAtStart
                    FROM MT_Main.dbo.T_Current_Activity
                    WHERE Database_Name = DB_Name() AND Update_State = 2
                    --
                    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                    If _myRowCount < 1 Then
                        _pauseLengthMinutesAtStart := 0;
                    End If;
                End If;

                -- Only update the Last_Query fields in MT_Main every 10 minutes when paused
                If DateDiff(minute, _lastUpdateTime, CURRENT_TIMESTAMP) >= 10 Then
                    UPDATE MT_Main.dbo.T_Process_Step_Control
                    SET Last_Query_Date = CURRENT_TIMESTAMP,
                        Last_Query_Description = _callingDBAndDescription,
                        Last_Query_Update_Count = Last_Query_Update_Count + 1,
                        Pause_Location = _callingDBAndDescription
                    WHERE Processing_Step_Name = _stepName
                    --
                    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                    _lastUpdateTime := CURRENT_TIMESTAMP;
                End If;

                -- Update Pause_Length_Minutes in T_Current_Activity every 2 minutes when paused
                If DateDiff(minute, _lastCurrentActivityUpdateTime, CURRENT_TIMESTAMP) >= 2 Then
                    _pauseLengthMinutes := DateDiff(minute, _pauseStartTime, CURRENT_TIMESTAMP);
                    If _pauseLengthMinutes < 1440 Then
                        _pauseLengthMinutes := DateDiff(second, _pauseStartTime, GetDate()) / 60.0;
                    End If;

                    UPDATE MT_Main.dbo.T_Current_Activity
                    SET Pause_Length_Minutes = _pauseLengthMinutesAtStart + _pauseLengthMinutes
                    WHERE Database_Name = DB_Name() AND Update_State = 2
                    --
                    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                    _lastCurrentActivityUpdateTime := CURRENT_TIMESTAMP;
                End If;

                -- Check for too much time elapsed since _pauseStartTime
                _pauseLengthMinutes := DateDiff(minute, _pauseStartTime, CURRENT_TIMESTAMP);
                If _pauseLengthMinutes / 60.0 >= _maximumPauseLengthHours Then
                    -- This SP has been looping for _maximumPauseLengthHours
                    -- Disable this processing step in T_Process_Step_Control and stop looping
                    UPDATE MT_Main.dbo.T_Process_Step_Control
                    SET Execution_State = 0
                    WHERE Processing_Step_Name = _stepName
                    --
                    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                    _message := format('Processing step %s has been paused for %s hours; updated Execution_State to 0 for this step and aborting the pause (called by %s)',
                                        _stepName, _maximumPauseLengthHours, _callingFunctionDescription);

                    Call post_log_entry ('Error', _message, 'Verify_Update_Enabled', 'pc');

                    _executionState := 0;
                    _pauseAborted := 1;
                End If;

                If (_executionState = 2 OR _executionState = 3) Then
                    -- Pause for _sleepTimeSeconds
                    WaitFor Delay _sleepTime
                End If;

            Else
            -- <c2>
                -- Execution is not paused
                -- Limit the updates to occur at least _minimumHealthUpdateIntervalSeconds apart
                --  to keep the DB transaction logs from growing too large
                -- Note: The purpose of the CASE statement in the Where clause is to prevent overflow
                --  errors when computing the difference between Last_Query_Date and the current time
                UPDATE MT_Main.dbo.T_Process_Step_Control
                SET Last_Query_Date = CURRENT_TIMESTAMP,
                    Last_Query_Description = _callingDBAndDescription,
                    Last_Query_Update_Count = Last_Query_Update_Count + 1
                WHERE Processing_Step_Name = _stepName AND
                      CASE WHEN Coalesce(Last_Query_Date, CURRENT_TIMESTAMP-1) <= CURRENT_TIMESTAMP-1 THEN _minimumHealthUpdateIntervalSeconds
                      ELSE DateDiff(second, Last_Query_Date, CURRENT_TIMESTAMP)
                      End If; >= @MinimumHealthUpdateIntervalSeconds
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;
            End If; -- </c2>
        END LOOP; -- </b2>
    End -- </a>

    If _pauseStartLogged = 1 Then
        -- Clear Pause_Location in MT_Main.dbo.T_Process_Step_Control
        UPDATE MT_Main.dbo.T_Process_Step_Control
        SET Pause_Location = ''
        WHERE Processing_Step_Name = _stepName
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        -- Store the final value for Pause_Length_Minutes in MT_Main.dbo.T_Current_Activity
        _pauseLengthMinutes := DateDiff(minute, _pauseStartTime, CURRENT_TIMESTAMP);
        If _pauseLengthMinutes < 1440 Then
            _pauseLengthMinutes := DateDiff(second, _pauseStartTime, GetDate()) / 60.0;
        End If;

        UPDATE MT_Main.dbo.T_Current_Activity
        SET Pause_Length_Minutes = _pauseLengthMinutesAtStart + _pauseLengthMinutes
        WHERE Database_Name = DB_Name() AND Update_State = 2
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        -- Post a message to T_Log_Entries
        If _pauseAborted = 0 Then
            _message := 'Resuming processing step ' || _stepName;
            Call post_log_entry ('Normal', _message, 'Verify_Update_Enabled', 'pc');
            _message := '';
        End If;
    End If;

    If _executionState = 1 Then
        _updateEnabled := 1;
    End If;

    If _updateEnabled = 0 AND _pauseAborted = 0 AND _myError = 0 Then
        _message := 'Processing step ' || _stepName || ' is disabled in MT_Main; aborting processing (called by ' || _callingFunctionDescription || ')';

        If _postLogEntryIfDisabled = 1 Then
            -- Post a warning to the log, but limit to one posting every hour
            Call post_log_entry ('Warning', _message, 'Verify_Update_Enabled', 'pc', _duplicateEntryHoldoffHours => 1);
        End If;
    End If;

Done:
    return _myError

END
$$;

COMMENT ON PROCEDURE pc.verify_update_enabled IS 'VerifyUpdateEnabled';

