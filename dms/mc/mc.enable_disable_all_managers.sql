--
-- Name: enable_disable_all_managers(text, text, boolean, boolean, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.enable_disable_all_managers(IN _managertypeidlist text DEFAULT ''::text, IN _managernamelist text DEFAULT ''::text, IN _enable boolean DEFAULT true, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
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
**    _enable              True to enable, false to disable
**    _infoOnly            When true, show the managers that would be updated
**
**  Example usage:
**
**      BEGIN;
**          -- Disable the Capture Task Managers and the Analysis Tool Managers on Pub-80 through Pub-89
**          CALL mc.enable_disable_all_managers(
**                _managerTypeIDList => '15, 11',
**                _managerNameList => 'Pub-8[0-9]%',
**                _enable => false,
**                _infoOnly => true
**              );
**      END;
**
**  Auth:   mem
**  Date:   05/09/2008
**          06/09/2011 mem - Created by extending code in DisableAllManagers
**                         - Now filtering on MT_Active > 0 in T_MgrTypes
**          01/30/2020 mem - Ported to PostgreSQL
**          03/23/2022 mem - Pass _results cursor to EnableDisableManagers
**          04/02/2022 mem - Use new procedure name
**          04/16/2022 mem - Use new object names
**          08/20/2022 mem - Concatenate messages returned by enable_disable_managers
**                         - Close the cursor after each call to enable_disable_managers
**                         - Update warnings shown when an exception occurs
**                         - Drop temp table before exiting the procedure
**          08/21/2022 mem - Replace temp table with array
**          08/24/2022 mem - Use function local_error_handler() to log errors
**          10/04/2022 mem - Change _enable and _infoOnly from integer to boolean
**
*****************************************************/
DECLARE
    _mgrTypeIDs int[];
    _mgrTypeID int;
    _msg text;
    _results refcursor;
    _sqlstate text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------
    --
    _enable := Coalesce(_enable, false);
    _managerTypeIDList := Coalesce(_managerTypeIDList, '');
    _managerNameList := Coalesce(_managerNameList, '');
    _infoOnly := Coalesce(_infoOnly, false);

    _message := '';
    _returnCode := '';

    If char_length(_managerTypeIDList) > 0 THEN
        -- Parse _managerTypeIDList
        --
        _mgrTypeIDs := ARRAY (
                        SELECT DISTINCT value
                        FROM public.parse_delimited_integer_list(_managerTypeIDList, ',')
                        ORDER BY Value );
    Else
        -- Populate _mgrTypeIDs with all manager types in mc.t_mgr_types
        --
        _mgrTypeIDs := ARRAY (
                        SELECT DISTINCT mgr_type_id
                        FROM mc.t_mgr_types
                        WHERE mgr_type_active > 0
                        ORDER BY mgr_type_id );
    End If;

    -----------------------------------------------
    -- Loop through the manager types in _mgrTypeIDs
    -- For each, call enable_disable_managers
    -----------------------------------------------

    FOREACH _mgrTypeID IN ARRAY _mgrTypeIDs
    LOOP

        Call mc.enable_disable_managers (
            _enable := _enable,
            _managerTypeID := _mgrTypeID,
            _managerNameList := _managerNameList,
            _infoOnly := _infoOnly,
            _results := _results,
            _message := _msg,
            _returnCode := _returnCode);

        -- Close the cursor
        If Not _results Is Null Then
            Close _results;
        End If;

        If Char_Length(_msg) > 0 Then
            -- Remove the "see also" message that does not apply when calling enable_disable_managers from this procedure
            _msg := Replace(_msg, '; see also "FETCH ALL FROM _results"', '');

            _message := public.append_to_text(_message, _msg, _delimiter := '; ');
        End If;

    END LOOP;

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

    _returnCode := _sqlstate;

END
$$;


ALTER PROCEDURE mc.enable_disable_all_managers(IN _managertypeidlist text, IN _managernamelist text, IN _enable boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE enable_disable_all_managers(IN _managertypeidlist text, IN _managernamelist text, IN _enable boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.enable_disable_all_managers(IN _managertypeidlist text, IN _managernamelist text, IN _enable boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'EnableDisableAllManagers';

