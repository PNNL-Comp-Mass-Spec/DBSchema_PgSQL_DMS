--
-- Name: ackmanagerupdaterequired(text, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE PROCEDURE mc.ackmanagerupdaterequired(_managername text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Acknowledges that a manager has seen that
**      ManagerUpdateRequired is True in the manager control DB
**
**      This SP will thus set ManagerUpdateRequired to False for this manager
**
**  Auth:   mem
**  Date:   01/16/2009 mem - Initial version
**          09/09/2009 mem - Added support for 'ManagerUpdateRequired' already being False
**          01/24/2020 mem - Ported to PostgreSQL
**          01/26/2020 mem - Add exception handler
**          01/29/2020 mem - Log errors to PostLogEntry
**          02/04/2020 mem - Rename columns to mgr_id and mgr_name
**
*****************************************************/
DECLARE
    _myRowCount int;
    _mgrID int;
    _paramID int;
    _sqlstate text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN
    _myRowCount := 0;

    _managerName := Trim(Coalesce(_managerName, ''));
    If (char_length(_managerName) = 0) Then
        _managerName := '??Undefined_Manager??';
    End If;

    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Confirm that the manager name is valid
    ---------------------------------------------------

    SELECT mgr_id INTO _mgrID
    FROM mc.t_mgrs
    WHERE mgr_name = _managerName::citext;

    IF NOT FOUND THEN
        _message := 'Could not find entry for manager: ' || _managername;
        _returnCode := 'U5202';
        Return;
    End If;

    ---------------------------------------------------
    -- Update the 'ManagerUpdateRequired' entry for this manager
    ---------------------------------------------------

    UPDATE mc.t_param_value PV
    SET value = 'False'
    FROM mc.t_param_type PT
    WHERE PT.param_id = PV.type_id AND
          PT.param_name = 'ManagerUpdateRequired' AND
          PV.mgr_id = _mgrID AND
          PV.value <> 'False';
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount > 0 Then
        _message := 'Acknowledged that update is required';
    Else
        -- No rows were updated; may need to make a new entry for 'ManagerUpdateRequired' in the t_param_value table

        SELECT param_id INTO _paramID
        FROM mc.t_param_type
        WHERE param_name = 'ManagerUpdateRequired';

        IF FOUND THEN
            If Exists (SELECT * FROM mc.t_param_value WHERE mgr_id = _mgrID AND type_id = _paramID) Then
                _message := 'ManagerUpdateRequired was already acknowledged in t_param_value';
            Else
                INSERT INTO mc.t_param_value (mgr_id, type_id, value)
                VALUES (_mgrID, _paramID, 'False');

                _message := 'Acknowledged that update is required (added new entry to t_param_value)';
            End If;
        End If;
    End If;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := 'Error updating ManagerUpdateRequired for ' || _managerName || ': ' || _exceptionMessage;
    _returnCode := _sqlstate;

    RAISE Warning 'Error: %', _message;
    RAISE warning '%', _exceptionContext;

    Call PostLogEntry ('Error', _message, 'AckManagerUpdateRequired', 'mc');

END
$$;


ALTER PROCEDURE mc.ackmanagerupdaterequired(_managername text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE ackmanagerupdaterequired(_managername text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.ackmanagerupdaterequired(_managername text, INOUT _message text, INOUT _returncode text) IS 'AckManagerUpdateRequired';

