--
-- Name: disable_archive_dependent_managers(boolean, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.disable_archive_dependent_managers(IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Disable managers that rely on MyEMSL
**
**  Arguments:
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   05/09/2008
**          07/24/2008 mem - Changed _ManagerTypeIDList from '1,2,3,4,8' to '2,3,8'
**          07/24/2008 mem - Changed _ManagerTypeIDList from '2,3,8' to '8'
**                         - Note that we do not include 15=CaptureTaskManager because capture tasks can still occur when the archive is unavailable
**                         - However, you should run Stored Procedure EnableDisableArchiveStepTools in the DMS_Capture database to disable the archive-dependent step tools
**          01/30/2020 mem - Ported to PostgreSQL
**          03/23/2022 mem - Use mc schema when calling Enable_Disable_All_Managers
**          04/02/2022 mem - Use new procedure name
**          10/04/2022 mem - Change _infoOnly from integer to boolean
**
*****************************************************/
DECLARE

BEGIN

    -- Disable Space managers (type 8)
    CALL mc.enable_disable_all_managers (
        _managerTypeIDList := '8',
        _managerNameList := '',
        _enable := false,
        _infoOnly := _infoOnly,
        _message := _message,
        _returnCode := _returnCode);

END
$$;


ALTER PROCEDURE mc.disable_archive_dependent_managers(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE disable_archive_dependent_managers(IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.disable_archive_dependent_managers(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'DisableArchiveDependentManagers';

