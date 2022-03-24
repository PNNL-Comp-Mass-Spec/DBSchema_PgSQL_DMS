--
-- Name: updatesinglemgrparamwork(text, text, text, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.updatesinglemgrparamwork(IN _paramname text, IN _newvalue text, IN _callinguser text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Changes single manager param for the EntryID values
**      defined in temporary table TmpParamValueEntriesToUpdate (created by the calling procedure)
**
**  Example table creation code:
**    CREATE TEMP TABLE TmpParamValueEntriesToUpdate (entry_id int NOT NULL)
**
**  Arguments:
**    _paramName   The parameter name
**    _newValue    The new value to assign for this parameter
**
**  Auth:   mem
**  Date:   04/16/2009
**          02/10/2020 mem - Ported to PostgreSQL
**          02/15/2020 mem - Provide a more detailed message of what was updated
**
*****************************************************/
DECLARE
    _rowCountUnchanged int := 0;
    _rowCountUpdated int := 0;
    _paramTypeID int;
    _targetState int;
BEGIN

    _message := '';
    _returnCode := '';

    -- Validate that _paramName is not blank
    If Coalesce(_paramName, '') = '' Then
        _message := 'Parameter Name is empty or null';
        RAISE WARNING '%', _message;
        _returnCode := 'U5315';
        Return;
    End If;

    -- Assure that _newValue is not null
    _newValue := Coalesce(_newValue, '');

    -- Lookup the param_type_id for param _paramName
    --
    SELECT param_id INTO _paramTypeID
    FROM mc.t_param_type
    WHERE param_name = _paramName::citext;

    If Not Found Then
        _message := 'Unknown Parameter Name: ' || _paramName;
        RAISE WARNING '%', _message;
        _returnCode := 'U5316';
        Return;
    End If;

    ---------------------------------------------------
    -- Count the number of rows that already have this value
    ---------------------------------------------------
    --
    SELECT Count(*) INTO _rowCountUnchanged
    FROM mc.t_param_value
    WHERE entry_id IN (SELECT entry_id FROM TmpParamValueEntriesToUpdate) AND
          Coalesce(value, '') = _newValue;

    ---------------------------------------------------
    -- Update the values defined in TmpParamValueEntriesToUpdate
    ---------------------------------------------------
    --
    UPDATE mc.t_param_value
    SET value = _newValue
    WHERE entry_id IN (SELECT entry_id FROM TmpParamValueEntriesToUpdate) AND
          Coalesce(value, '') <> _newValue;
    --
    GET DIAGNOSTICS _rowCountUpdated = ROW_COUNT;

    If _rowCountUpdated > 0 And char_length(Coalesce(_callingUser, '')) > 0 Then

        -- _callingUser is defined
        -- Items need to be updated in mc.t_param_value and possibly in mc.t_event_log

        ---------------------------------------------------
        -- Create a temporary table that will hold the entry_id
        -- values that need to be updated in mc.t_param_value
        ---------------------------------------------------

        Drop Table If Exists TmpIDUpdateList;

        CREATE TEMP TABLE TmpIDUpdateList (
            TargetID int NOT NULL
        );

        CREATE UNIQUE INDEX IX_TmpIDUpdateList ON TmpIDUpdateList (TargetID);

        -- Populate TmpIDUpdateList with entry_id values for mc.t_param_value, then call AlterEnteredByUserMultiID
        --
        INSERT INTO TmpIDUpdateList (TargetID)
        SELECT entry_id
        FROM TmpParamValueEntriesToUpdate;

        Call public.AlterEnteredByUserMultiID ('mc', 't_param_value', 'entry_id', _callingUser, _entryDateColumnName => 'last_affected', _message => _message);

        If _paramName::citext = 'mgractive' or _paramTypeID = 17 Then
            -- Triggers trig_i_t_param_value and trig_u_t_param_value make an entry in
            --  mc.t_event_log whenever mgractive (param TypeID = 17) is changed

            -- Call AlterEventLogEntryUserMultiID
            -- to alter the entered_by field in mc.t_event_log

            If _newValue::citext = 'True' Then
                _targetState := 1;
            Else
                _targetState := 0;
            End If;

            -- Populate TmpIDUpdateList with Manager ID values, then call AlterEventLogEntryUserMultiID
            Truncate Table TmpIDUpdateList;

            INSERT INTO TmpIDUpdateList (TargetID)
            SELECT PV.mgr_id
            FROM mc.t_param_value PV
            WHERE PV.entry_id IN (SELECT entry_id FROM TmpParamValueEntriesToUpdate);

            Call public.AlterEventLogEntryUserMultiID ('mc', 1, _targetState, _callingUser, _message => _message);
        End If;

    End If;

    If _message = '' Then
        If _rowCountUpdated = 0 Then
            _message := 'All ' || _rowCountUnchanged || ' row(s) in mc.t_param_value already have ' || _paramname || ' = ' || _newValue;
        Else
            _message := 'Updated ' || _rowCountUpdated || ' row(s) in mc.t_param_value to have ' || _paramname || ' = ' || _newValue;
        End If;
    End If;
END
$$;


ALTER PROCEDURE mc.updatesinglemgrparamwork(IN _paramname text, IN _newvalue text, IN _callinguser text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE updatesinglemgrparamwork(IN _paramname text, IN _newvalue text, IN _callinguser text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.updatesinglemgrparamwork(IN _paramname text, IN _newvalue text, IN _callinguser text, INOUT _message text, INOUT _returncode text) IS 'UpdateSingleMgrParamWork';

