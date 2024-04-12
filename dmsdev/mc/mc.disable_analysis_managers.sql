--
-- Name: disable_analysis_managers(boolean, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.disable_analysis_managers(IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Disable all analysis managers
**
**  Arguments:
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   05/09/2008
**          10/09/2009 mem - Changed _ManagerTypeIDList to 11
**          06/09/2011 mem - Now calling Enable_Disable_All_Managers
**          01/30/2020 mem - Ported to PostgreSQL
**          03/23/2022 mem - Use mc schema when calling Enable_Disable_All_Managers
**          04/02/2022 mem - Use new procedure name
**          10/04/2022 mem - Change _infoOnly from integer to boolean
**
*****************************************************/
DECLARE

BEGIN
    CALL mc.enable_disable_all_managers (
        _managerTypeIDList := '11',
        _managerNameList := '',
        _enable := false,
        _infoOnly := _infoOnly,
        _message := _message,
        _returnCode := _returnCode);

END
$$;


ALTER PROCEDURE mc.disable_analysis_managers(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE disable_analysis_managers(IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.disable_analysis_managers(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'DisableAnalysisManagers';

