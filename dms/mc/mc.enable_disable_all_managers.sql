--
-- Name: enable_disable_all_managers(text, text, integer, integer, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.enable_disable_all_managers(IN _managertypeidlist text DEFAULT ''::text, IN _managernamelist text DEFAULT ''::text, IN _enable integer DEFAULT 1, IN _infoonly integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Enables or disables all managers, optionally filtering by manager type ID or manager name
**
**  Arguments:
**    _managerTypeIDList   Optional: comma separated list of manager type IDs to disable, e.g. '1, 2, 3'
**    _managerNameList     Optional: if defined, only managers specified here will be enabled;
**                         Supports the % wildcard; also supports 'all'
**    _enable              1 to enable, 0 to disable
**    _infoOnly            When non-zero, show the managers that would be updated
**
**  Auth:   mem
**  Date:   05/09/2008
**          06/09/2011 mem - Created by extending code in DisableAllManagers
**                         - Now filtering on MT_Active > 0 in T_MgrTypes
**          01/30/2020 mem - Ported to PostgreSQL
**          03/23/2022 mem - Pass _results cursor to EnableDisableManagers
**          04/02/2022 mem - Use new procedure name
**          04/16/2022 mem - Use new object names
**
*****************************************************/
DECLARE
    _mgrTypeID int;
    _results refcursor;
    _sqlstate text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------
    --
    _enable := Coalesce(_enable, 0);
    _managerTypeIDList := Coalesce(_managerTypeIDList, '');
    _managerNameList := Coalesce(_managerNameList, '');
    _infoOnly := Coalesce(_infoOnly, 0);

    _message := '';
    _returnCode := '';

    DROP TABLE IF EXISTS TmpManagerTypeIDs;

    CREATE TEMP TABLE TmpManagerTypeIDs (
        mgr_type_id int NOT NULL
    );

    If char_length(_managerTypeIDList) > 0 THEN
        -- Parse _managerTypeIDList
        --
        INSERT INTO TmpManagerTypeIDs (mgr_type_id)
        SELECT DISTINCT value
        FROM public.parse_delimited_integer_list(_managerTypeIDList, ',')
        ORDER BY Value;
    Else
        -- Populate TmpManagerTypeIDs with all manager types in mc.t_mgr_types
        --
        INSERT INTO TmpManagerTypeIDs (mgr_type_id)
        SELECT DISTINCT mgr_type_id
        FROM mc.t_mgr_types
        WHERE mgr_type_active > 0
        ORDER BY mgr_type_id;
    End If;

    -----------------------------------------------
    -- Loop through the manager types in TmpManagerTypeIDs
    -- For each, call enable_disable_managers
    -----------------------------------------------

    FOR _mgrTypeID IN
        SELECT mgr_type_id
        FROM TmpManagerTypeIDs
    LOOP

        Call mc.enable_disable_managers (
            _enable := _enable,
            _managerTypeID := _mgrTypeID,
            _managerNameList := _managerNameList,
            _infoOnly := _infoOnly,
            _results := _results,
            _message := _message,
            _returnCode := _returnCode);

    End Loop;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := 'Error updating enabling/disabling all managers: ' || _exceptionMessage;
    _returnCode := _sqlstate;

    RAISE Warning 'Error: %', _message;
    RAISE warning '%', _exceptionContext;

    Call post_log_entry ('Error', _message, 'EnableDisableAllManagers', 'mc');

END
$$;


ALTER PROCEDURE mc.enable_disable_all_managers(IN _managertypeidlist text, IN _managernamelist text, IN _enable integer, IN _infoonly integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE enable_disable_all_managers(IN _managertypeidlist text, IN _managernamelist text, IN _enable integer, IN _infoonly integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.enable_disable_all_managers(IN _managertypeidlist text, IN _managernamelist text, IN _enable integer, IN _infoonly integer, INOUT _message text, INOUT _returncode text) IS 'EnableDisableAllManagers';

