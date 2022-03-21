--
-- Name: reportmanagererrorcleanup(text, integer, text, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.reportmanagererrorcleanup(IN _managername text, IN _state integer DEFAULT 0, IN _failuremsg text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Reports that the manager tried to auto-cleanup
**      when there is a flag file or non-empty working directory
**
**  Arguments:
**    _managername   Manager name
**    _state         1 = Cleanup Attempt start, 2 = Cleanup Successful, 3 = Cleanup Failed
**    _failuremsg    Failure message (only used if _state is 3)
**
**  Auth:   mem
**  Date:   09/10/2009 mem - Initial version
**          02/07/2020 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _mgrInfo record;
    _mgrID int;
    _paramID int;
    _messageType text;
    _cleanupMode text;
    _sqlstate text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN
    ---------------------------------------------------
    -- Cleanup the inputs
    ---------------------------------------------------

    _managerName := Coalesce(_managerName, '');
    _state := Coalesce(_state, 0);
    _failureMsg := Coalesce(_failureMsg, '');
    _message := '';
    _returncode := '';
    
    ---------------------------------------------------
    -- Confirm that the manager name is valid
    ---------------------------------------------------

    SELECT mgr_id, mgr_name INTO _mgrInfo
    FROM mc.t_mgrs
    WHERE mgr_name = _managerName;

    If Not Found Then
        _message := 'Could not find entry for manager: ' || _managerName;
        _returncode := 'U5202';
        Return;
    End If;

    _mgrID       := _mgrInfo.mgr_id;
    _managerName := _mgrInfo.mgr_name;

    ---------------------------------------------------
    -- Validate _state
    ---------------------------------------------------

    If _state < 1 Or _state > 3 Then
        _message := 'Invalid value for _state; should be 1, 2 or 3, not ' || _state;
        _returncode := 'U5203';
        Return;
    End If;

    ---------------------------------------------------
    -- Log this cleanup event
    ---------------------------------------------------

    _messageType := 'Error';
    _message := 'Unknown _state value';

    If _state = 1 Then
        _messageType := 'Normal';
        _message := 'Manager ' || _managerName || ' is attempting auto error cleanup';
    End If;

    If _state = 2 Then
        _messageType := 'Normal';
        _message := 'Automated error cleanup succeeded for ' || _managerName;
    End If;

    If _state = 3 Then
        _messageType := 'Normal';
        _message := 'Automated error cleanup failed for ' || _managerName;
        If _failureMsg <> '' Then
            _message := _message || '; ' || _failureMsg;
        End If;
    End If;

    Call PostLogEntry (_messageType, _message, 'ReportManagerErrorCleanup', 'mc');

    ---------------------------------------------------
    -- Lookup the value of ManagerErrorCleanupMode in mc.t_param_value
    ---------------------------------------------------

    SELECT PV.value INTO _cleanupMode
    FROM mc.t_param_value PV
         INNER JOIN mc.t_param_type PT
           ON PV.type_id = PT.param_id
    WHERE PT.param_name = 'ManagerErrorCleanupMode' AND
          PV.mgr_id = _mgrID;

    If Not Found Then
        -- Entry not found; make a new entry for 'ManagerErrorCleanupMode' in the mc.t_param_value table

        SELECT param_id INTO _paramID
        FROM mc.t_param_type
        WHERE param_name = 'ManagerErrorCleanupMode';

        If Found Then
            INSERT INTO mc.t_param_value (mgr_id, type_id, value)
            VALUES (_mgrID, _paramID, '0');

            _cleanupMode := '0';
        End If;
    End If;

    If Trim(_cleanupMode) = '1' Then

        -- Manager is set to auto-cleanup only once; change 'ManagerErrorCleanupMode' to 0
        --
        UPDATE mc.t_param_value
        SET value = '0'
        WHERE entry_id IN (
            SELECT PV.entry_id
            FROM mc.t_param_value PV
                 INNER JOIN mc.t_param_type PT
                   ON PV.type_id = PT.param_id
            WHERE PT.param_name = 'ManagerErrorCleanupMode' AND
                  PV.mgr_id = _mgrID);

        If Not Found Then
            _message := _message || '; Entry not found in mc.t_param_value for ManagerErrorCleanupMode; this is unexpected';
        Else
            _message := _message || '; Changed ManagerErrorCleanupMode to 0 in mc.t_param_value';
        End If;
    End If;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := 'Error updating ManagerErrorCleanupMode in mc.t_param_value: ' || _exceptionMessage;
    _returnCode := _sqlstate;

    RAISE Warning 'Error: %', _message;
    RAISE warning '%', _exceptionContext;

    Call PostLogEntry ('Error', _message, 'ReportManagerErrorCleanup', 'mc');

END
$$;


ALTER PROCEDURE mc.reportmanagererrorcleanup(IN _managername text, IN _state integer, IN _failuremsg text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE reportmanagererrorcleanup(IN _managername text, IN _state integer, IN _failuremsg text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.reportmanagererrorcleanup(IN _managername text, IN _state integer, IN _failuremsg text, INOUT _message text, INOUT _returncode text) IS 'ReportManagerErrorCleanup';

