--
-- Name: report_manager_error_cleanup(text, integer, text, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.report_manager_error_cleanup(IN _managername text, IN _state integer DEFAULT 0, IN _failuremsg text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
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
**  Example Usage:
**
**      CALL mc.report_manager_error_cleanup ('monroe_analysis', 2);
**
**  Auth:   mem
**  Date:   09/10/2009 mem - Initial version
**          02/07/2020 mem - Ported to PostgreSQL
**          04/16/2022 mem - Use new procedure name
**          08/20/2022 mem - Update warnings shown when an exception occurs
**          08/24/2022 mem - Use function local_error_handler() to log errors
**          01/31/2023 mem - Use new column names in tables
**          05/07/2023 mem - Remove unused variable
**          05/10/2023 mem - Capitalize procedure name sent to post_log_entry
**          05/30/2023 mem - Use format() for string concatenation
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _mgrInfo record;
    _mgrID int;
    _paramTypeID int;
    _messageType text;
    _cleanupMode text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returncode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _managerName := Coalesce(_managerName, '');
    _state       := Coalesce(_state, 0);
    _failureMsg  := Coalesce(_failureMsg, '');

    ---------------------------------------------------
    -- Confirm that the manager name is valid
    ---------------------------------------------------

    SELECT mgr_id, mgr_name
    INTO _mgrInfo
    FROM mc.t_mgrs
    WHERE mgr_name = _managerName::citext;

    If Not Found Then
        _message := format('Could not find entry for manager: %s', _managerName);
        _returncode := 'U5202';
        RETURN;
    End If;

    _mgrID       := _mgrInfo.mgr_id;
    _managerName := _mgrInfo.mgr_name;

    ---------------------------------------------------
    -- Validate _state
    ---------------------------------------------------

    If _state < 1 Or _state > 3 Then
        _message := format('Invalid value for _state; should be 1, 2 or 3, not %s', _state);
        _returncode := 'U5203';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Log this cleanup event
    ---------------------------------------------------

    _messageType := 'Error';
    _message := 'Unknown _state value';

    If _state = 1 Then
        _messageType := 'Normal';
        _message := format('Manager %s is attempting auto error cleanup', _managerName);
    End If;

    If _state = 2 Then
        _messageType := 'Normal';
        _message := format('Automated error cleanup succeeded for %s', _managerName);
    End If;

    If _state = 3 Then
        _messageType := 'Normal';
        _message := format('Automated error cleanup failed for %s', _managerName);

        If _failureMsg <> '' Then
            _message := format('%s; %s', _message, _failureMsg);
        End If;

    End If;

    CALL public.post_log_entry (_messageType, _message, 'Report_Manager_Error_Cleanup', 'mc');

    ---------------------------------------------------
    -- Lookup the value of ManagerErrorCleanupMode in mc.t_param_value
    ---------------------------------------------------

    SELECT PV.value
    INTO _cleanupMode
    FROM mc.t_param_value PV
         INNER JOIN mc.t_param_type PT
           ON PV.param_type_id = PT.param_type_id
    WHERE PT.param_name = 'ManagerErrorCleanupMode' AND
          PV.mgr_id = _mgrID;

    If Not Found Then
        -- Entry not found; make a new entry for 'ManagerErrorCleanupMode' in the mc.t_param_value table

        SELECT param_type_id
        INTO _paramTypeID
        FROM mc.t_param_type
        WHERE param_name = 'ManagerErrorCleanupMode';

        If FOUND Then
            INSERT INTO mc.t_param_value (mgr_id, param_type_id, value)
            VALUES (_mgrID, _paramTypeID, '0');

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
                   ON PV.param_type_id = PT.param_type_id
            WHERE PT.param_name = 'ManagerErrorCleanupMode' AND
                  PV.mgr_id = _mgrID);

        If Not Found Then
            _message := format('%s; Entry not found in mc.t_param_value for ManagerErrorCleanupMode; this is unexpected', _message);
        Else
            _message := format('%s; Changed ManagerErrorCleanupMode to 0 in mc.t_param_value', _message);
        End If;
    End If;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState         = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionDetail  = pg_exception_detail,
            _exceptionContext = pg_exception_context;

    _message := local_error_handler (
                    _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                    _logError => true);

    _returnCode := _sqlState;

END
$$;


ALTER PROCEDURE mc.report_manager_error_cleanup(IN _managername text, IN _state integer, IN _failuremsg text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE report_manager_error_cleanup(IN _managername text, IN _state integer, IN _failuremsg text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.report_manager_error_cleanup(IN _managername text, IN _state integer, IN _failuremsg text, INOUT _message text, INOUT _returncode text) IS 'ReportManagerErrorCleanup';

