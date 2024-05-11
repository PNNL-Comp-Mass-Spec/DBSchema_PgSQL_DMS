--
-- Name: enable_space_managers(boolean, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.enable_space_managers(IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Enable the space managers
**
**  Arguments:
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   06/09/2011 mem - Initial Version
**          02/05/2020 mem - Ported to PostgreSQL
**          03/23/2022 mem - Use mc schema when calling Enable_Disable_All_Managers
**          04/02/2022 mem - Use new procedure name
**          10/04/2022 mem - Change _infoOnly from integer to boolean
**
*****************************************************/
DECLARE

BEGIN

    -- Enable Space managers (type 8)
    CALL mc.enable_disable_all_managers (
        _managerTypeIDList := '8',
        _managerNameList := 'All',
        _enable := true,
        _infoOnly := _infoOnly,
        _message := _message,
        _returnCode := _returnCode);

END
$$;


ALTER PROCEDURE mc.enable_space_managers(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE enable_space_managers(IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.enable_space_managers(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'EnableSpaceManagers (previously EnableArchiveDependentManagers)';

