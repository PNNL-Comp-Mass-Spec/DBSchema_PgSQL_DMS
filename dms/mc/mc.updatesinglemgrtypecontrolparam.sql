--
-- Name: updatesinglemgrtypecontrolparam(text, text, text, text, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.updatesinglemgrtypecontrolparam(IN _paramname text, IN _newvalue text, IN _managertypeidlist text, IN _callinguser text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Changes single manager params for set of given manager Types
**
**  Arguments:
**    _paramName          The parameter name to update
**    _newValue           The new value to assign for this parameter
**    _managerTypeIDList  Manager type IDs to update (11=Analyis Manager, 15=Capture Task Manager, etc.)
**
**  Auth:   jds
**  Date:   07/17/2007
**          07/31/2007 grk - changed for 'controlfromwebsite' no longer a parameter
**          03/30/2009 mem - Added optional parameter _callingUser; if provided, then will call AlterEnteredByUserMultiID and possibly AlterEventLogEntryUserMultiID
**          04/16/2009 mem - Now calling UpdateSingleMgrParamWork to perform the updates
**          02/15/2020 mem - Ported to PostgreSQL
**          03/23/2022 mem - Use mc schema when calling UpdateSingleMgrParamWork
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _sqlstate text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN

    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Create a temporary table that will hold the entry_id
    -- values that need to be updated in mc.t_param_value
    ---------------------------------------------------
    DROP TABLE IF EXISTS TmpParamValueEntriesToUpdate;

    CREATE TEMP TABLE TmpParamValueEntriesToUpdate (
        entry_id int NOT NULL
    );

    CREATE UNIQUE INDEX IX_TmpParamValueEntriesToUpdate ON TmpParamValueEntriesToUpdate (entry_id);

    ---------------------------------------------------
    -- Find the _paramName entries for the Manager Types in _managerTypeIDList
    ---------------------------------------------------
    --
    INSERT INTO TmpParamValueEntriesToUpdate (entry_id)
    SELECT PV.entry_id
    FROM mc.t_param_value PV
         INNER JOIN mc.t_param_type PT
           ON PV.type_id = PT.param_id
         INNER JOIN mc.t_mgrs M
           ON M.mgr_id = PV.mgr_id
    WHERE PT.param_name = _paramName AND
          M.mgr_type_id IN ( SELECT value
                             FROM public.udf_parse_delimited_integer_list(_managerTypeIDList, ',')
                           ) AND
          M.control_from_website > 0;

    IF NOT FOUND THEN
        _message := 'Did not find any managers of type ' || _managerTypeIDList || ' with parameter ' || _paramName || ' and control_from_website > 0';
        _returnCode := 'U5100';
        Return;
    END IF;

    ---------------------------------------------------
    -- Call UpdateSingleMgrParamWork to perform the update
    -- Note that it calls AlterEnteredByUserMultiID and AlterEventLogEntryUserMultiID for _callingUser
    ---------------------------------------------------
    --
    Call mc.UpdateSingleMgrParamWork (_paramName, _newValue, _callingUser, _message => _message, _returnCode => _returnCode);

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := format('Error %s %s: %s',
                _currentOperation, _currentTargetTable, _exceptionMessage);

    RAISE Warning '%', _message;
    RAISE warning '%', _exceptionContext;

    Call PostLogEntry ('Error', _message, 'UpdateSingleMgrTypeControlParam', 'public');

END
$$;


ALTER PROCEDURE mc.updatesinglemgrtypecontrolparam(IN _paramname text, IN _newvalue text, IN _managertypeidlist text, IN _callinguser text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE updatesinglemgrtypecontrolparam(IN _paramname text, IN _newvalue text, IN _managertypeidlist text, IN _callinguser text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.updatesinglemgrtypecontrolparam(IN _paramname text, IN _newvalue text, IN _managertypeidlist text, IN _callinguser text, INOUT _message text, INOUT _returncode text) IS 'UpdateSingleMgrTypeControlParam';

