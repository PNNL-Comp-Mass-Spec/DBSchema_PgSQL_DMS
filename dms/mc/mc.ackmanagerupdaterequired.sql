--
-- Name: ackmanagerupdaterequired(text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE PROCEDURE mc.ackmanagerupdaterequired(_managername text, INOUT _message text DEFAULT ''::text)
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
**
*****************************************************/
DECLARE
    _myError int;
    _myRowCount int;
    _mgrID int;
    _paramID int;
BEGIN
    _myError := 0;
    _myRowCount := 0;

    _message := '';

    ---------------------------------------------------
    -- Confirm that the manager name is valid
    ---------------------------------------------------

    SELECT m_id INTO _mgrID
    FROM mc.t_mgrs
    WHERE m_name = _managerName::citext;

    IF NOT FOUND THEN
        _myError := 52002;
        _message := 'Could not find entry for manager: ' || _managername;
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

    -- RAISE NOTICE '%', _message;
END
$$;


ALTER PROCEDURE mc.ackmanagerupdaterequired(_managername text, INOUT _message text) OWNER TO d3l243;

--
-- Name: PROCEDURE ackmanagerupdaterequired(_managername text, INOUT _message text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.ackmanagerupdaterequired(_managername text, INOUT _message text) IS 'AckManagerUpdateRequired';

