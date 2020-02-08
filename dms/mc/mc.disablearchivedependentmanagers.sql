--
-- Name: disablearchivedependentmanagers(integer, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.disablearchivedependentmanagers(_infoonly integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Disables managers that rely on MyEMSL
**
**  Auth:   mem
**  Date:   05/09/2008
**          07/24/2008 mem - Changed _ManagerTypeIDList from '1,2,3,4,8' to '2,3,8'
**          07/24/2008 mem - Changed _ManagerTypeIDList from '2,3,8' to '8'
**                         - Note that we do not include 15=CaptureTaskManager because capture tasks can still occur when the archive is unavailable
**                         - However, you should run Stored Procedure EnableDisableArchiveStepTools in the DMS_Capture database to disable the archive-dependent step tools
**          01/30/2020 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN

    -- Disable Space managers (type 8)
    Call EnableDisableAllManagers (
        _managerTypeIDList := '8', 
        _managerNameList := '', 
        _enable := 0,
        _infoOnly := _infoOnly, 
        _message := _message,
        _returnCode := _returnCode);

END
$$;


ALTER PROCEDURE mc.disablearchivedependentmanagers(_infoonly integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE disablearchivedependentmanagers(_infoonly integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.disablearchivedependentmanagers(_infoonly integer, INOUT _message text, INOUT _returncode text) IS 'DisableArchiveDependentManagers';

