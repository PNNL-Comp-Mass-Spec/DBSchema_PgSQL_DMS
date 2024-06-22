--
-- Name: update_single_mgr_type_control_param(text, text, text, text, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.update_single_mgr_type_control_param(IN _paramname text, IN _newvalue text, IN _managertypeidlist text, IN _callinguser text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Change a single manager parameter for a set of given manager types
**
**  Arguments:
**    _paramName            The parameter name to update
**    _newValue             The new value to assign for this parameter
**    _managerTypeIDList    Manager type IDs to update (11=Analyis Manager, 15=Capture Task Manager, etc.)
**    _callingUser          Username of the calling user
**    _message              Status message
**    _returnCode           Return code
**
**  Example usage:
**      CALL mc.update_single_mgr_type_control_param('ManagerUpdateRequired', 'False', '11, 15')
**
**  Auth:   jds
**  Date:   07/17/2007
**          07/31/2007 grk - Changed for 'controlfromwebsite' no longer a parameter
**          03/30/2009 mem - Added optional parameter _callingUser; if provided, then will call alter_entered_by_user_multi_id and possibly alter_event_log_entry_user_multi_id
**          04/16/2009 mem - Now calling Update_Single_Mgr_Param_Work to perform the updates
**          02/15/2020 mem - Ported to PostgreSQL
**          03/23/2022 mem - Use mc schema when calling Update_Single_Mgr_Param_Work
**          04/02/2022 mem - Use new procedure name
**          04/16/2022 mem - Use new object names
**          08/20/2022 mem - Update warnings shown when an exception occurs
**                         - Drop temp table before exiting the procedure
**          08/21/2022 mem - Update return code
**          08/24/2022 mem - Use function local_error_handler() to log errors
**          01/31/2023 mem - Use new column names in tables
**          05/07/2023 mem - Remove unused variable
**          05/22/2023 mem - Capitalize reserved word
**          05/23/2023 mem - Use format() for string concatenation
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_integer_list for a comma-separated list
**          10/11/2023 mem - Ignore case when filtering on parameter name
**
*****************************************************/
DECLARE

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Create a temporary table that will hold the entry_id
    -- values that need to be updated in mc.t_param_value
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_ParamValueEntriesToUpdate (
        entry_id int NOT NULL
    );

    CREATE UNIQUE INDEX IX_Tmp_ParamValueEntriesToUpdate ON Tmp_ParamValueEntriesToUpdate (entry_id);

    ---------------------------------------------------
    -- Find the _paramName entries for the Manager Types in _managerTypeIDList
    ---------------------------------------------------

    INSERT INTO Tmp_ParamValueEntriesToUpdate (entry_id)
    SELECT PV.entry_id
    FROM mc.t_param_value PV
         INNER JOIN mc.t_param_type PT
           ON PV.param_type_id = PT.param_type_id
         INNER JOIN mc.t_mgrs M
           ON M.mgr_id = PV.mgr_id
    WHERE PT.param_name = _paramName::citext AND
          M.mgr_type_id IN (SELECT value
                            FROM public.parse_delimited_integer_list(_managerTypeIDList)
                           ) AND
          M.control_from_website > 0;

    If Not FOUND Then
        _message := format('Did not find any managers of type %s with parameter %s and control_from_website > 0', _managerTypeIDList, _paramName);
        _returnCode := 'U5201';

        DROP TABLE Tmp_ParamValueEntriesToUpdate;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Call update_single_mgr_param_work to perform the update
    -- Note that it calls alter_entered_by_user_multi_id and alter_event_log_entry_user_multi_id for _callingUser
    ---------------------------------------------------

    CALL mc.update_single_mgr_param_work (
                _paramName,
                _newValue,
                _callingUser,
                _message => _message,           -- Output
                _returnCode => _returnCode);    -- Output

    DROP TABLE Tmp_ParamValueEntriesToUpdate;

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

    DROP TABLE IF EXISTS Tmp_ParamValueEntriesToUpdate;
END
$$;


ALTER PROCEDURE mc.update_single_mgr_type_control_param(IN _paramname text, IN _newvalue text, IN _managertypeidlist text, IN _callinguser text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_single_mgr_type_control_param(IN _paramname text, IN _newvalue text, IN _managertypeidlist text, IN _callinguser text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.update_single_mgr_type_control_param(IN _paramname text, IN _newvalue text, IN _managertypeidlist text, IN _callinguser text, INOUT _message text, INOUT _returncode text) IS 'UpdateSingleMgrTypeControlParam';

