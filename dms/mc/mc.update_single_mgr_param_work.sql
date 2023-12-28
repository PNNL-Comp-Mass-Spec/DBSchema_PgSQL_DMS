--
-- Name: update_single_mgr_param_work(text, text, text, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.update_single_mgr_param_work(IN _paramname text, IN _newvalue text, IN _callinguser text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Changes single manager param for the EntryID values
**      defined in temporary table Tmp_ParamValueEntriesToUpdate (created by the calling procedure)
**
**  Example table creation code:
**    CREATE TEMP TABLE Tmp_ParamValueEntriesToUpdate (entry_id int NOT NULL)
**
**  Arguments:
**    _paramName   The parameter name
**    _newValue    The new value to assign for this parameter
**
**  Auth:   mem
**  Date:   04/16/2009
**          02/10/2020 mem - Ported to PostgreSQL
**          02/15/2020 mem - Provide a more detailed message of what was updated
**          08/21/2022 mem - Update return codes
**          10/04/2022 mem - Rename temporary tables
**                         - Move temporary table drop to the end of the if block
**          01/31/2023 mem - Use new column names in tables
**          05/22/2023 mem - Use format() for string concatenation
**          07/11/2023 mem - Use COUNT(PV.entry_id) instead of COUNT(*)
**          07/27/2023 mem - Use local variable for the return value of _message from alter_event_log_entry_user_multi_id
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          12/28/2023 mem - Use a variable for target type when calling alter_event_log_entry_user_multi_id()
**
*****************************************************/
DECLARE
    _rowCountUnchanged int := 0;
    _rowCountUpdated int := 0;
    _paramTypeID int;
    _targetState int;
    _targetType int;
    _alterEnteredByMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    -- Validate that _paramName is not blank
    If Coalesce(_paramName, '') = '' Then
        _message := 'Parameter Name is empty or null';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    -- Assure that _newValue is not null
    _newValue := Trim(Coalesce(_newValue, ''));

    -- Lookup the param_type_id for param _paramName
    --
    SELECT param_type_id
    INTO _paramTypeID
    FROM mc.t_param_type
    WHERE param_name = _paramName::citext;

    If Not Found Then
        _message := format('Unknown Parameter Name: %s', _paramName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Count the number of rows that already have this value
    ---------------------------------------------------

    SELECT COUNT(PV.entry_id)
    INTO _rowCountUnchanged
    FROM mc.t_param_value PV
    WHERE PV.entry_id IN (SELECT entry_id FROM Tmp_ParamValueEntriesToUpdate) AND
          Coalesce(PV.value, '') = _newValue;

    ---------------------------------------------------
    -- Update the values defined in Tmp_ParamValueEntriesToUpdate
    ---------------------------------------------------

    UPDATE mc.t_param_value
    SET value = _newValue
    WHERE entry_id IN (SELECT entry_id FROM Tmp_ParamValueEntriesToUpdate) AND
          Coalesce(value, '') <> _newValue;
    --
    GET DIAGNOSTICS _rowCountUpdated = ROW_COUNT;

    If _rowCountUpdated > 0 And char_length(Coalesce(_callingUser, '')) > 0 Then

        ---------------------------------------------------
        -- _callingUser is defined
        -- Items need to be updated in mc.t_param_value and possibly in mc.t_event_log
        ---------------------------------------------------

        -- Create a temporary table that will hold the entry_id
        -- values that need to be updated in mc.t_param_value
        --
        CREATE TEMP TABLE Tmp_ID_Update_List (
            TargetID int NOT NULL
        );

        CREATE UNIQUE INDEX IX_Tmp_ID_Update_List ON Tmp_ID_Update_List (TargetID);

        -- Populate Tmp_ID_Update_List with entry_id values for mc.t_param_value, then call alter_entered_by_user_multi_id
        --
        INSERT INTO Tmp_ID_Update_List (TargetID)
        SELECT entry_id
        FROM Tmp_ParamValueEntriesToUpdate;

        CALL public.alter_entered_by_user_multi_id ('mc', 't_param_value', 'entry_id', _callingUser, _entryDateColumnName => 'last_affected', _message => _alterEnteredByMessage);

        RAISE INFO '%', _alterEnteredByMessage;

        If _paramName::citext = 'mgractive' Or _paramTypeID = 17 Then
            -- Triggers trig_i_t_param_value and trig_u_t_param_value make an entry in
            -- mc.t_event_log whenever mgractive (param TypeID = 17) is changed

            -- Call alter_event_log_entry_user_multi_id to alter the entered_by field in mc.t_event_log

            If _newValue::citext = 'True' Then
                _targetState := 1;
            Else
                _targetState := 0;
            End If;

            -- Populate Tmp_ID_Update_List with Manager ID values, then call alter_event_log_entry_user_multi_id
            TRUNCATE TABLE Tmp_ID_Update_List;

            INSERT INTO Tmp_ID_Update_List (TargetID)
            SELECT PV.mgr_id
            FROM mc.t_param_value PV
            WHERE PV.entry_id IN (SELECT entry_id FROM Tmp_ParamValueEntriesToUpdate);

            -- Target type 1 corresponds to the 'mgractive' parameter in table T_Param_Value
            _targetType := 1;

            CALL public.alter_event_log_entry_user_multi_id ('mc', _targetType, _targetState, _callingUser, _message => _alterEnteredByMessage);

            RAISE INFO '%', _alterEnteredByMessage;
        End If;

        DROP TABLE Tmp_ID_Update_List;
    End If;

    If _message = '' Then
        If _rowCountUpdated = 0 Then
            _message := format('All %s row(s) in mc.t_param_value already have %s = %s', _rowCountUnchanged, _paramName, _newValue);
        Else
            _message := format('Updated %s row(s) in mc.t_param_value to have %s = %s', _rowCountUpdated, _paramName, _newValue);
        End If;
    End If;
END
$$;


ALTER PROCEDURE mc.update_single_mgr_param_work(IN _paramname text, IN _newvalue text, IN _callinguser text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_single_mgr_param_work(IN _paramname text, IN _newvalue text, IN _callinguser text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.update_single_mgr_param_work(IN _paramname text, IN _newvalue text, IN _callinguser text, INOUT _message text, INOUT _returncode text) IS 'UpdateSingleMgrParamWork';

