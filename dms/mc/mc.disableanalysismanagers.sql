--
-- Name: disableanalysismanagers(integer, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE PROCEDURE mc.disableanalysismanagers(_infoonly integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Disables all analysis managers
**
**  Auth:   mem
**  Date:   05/09/2008
**          10/09/2009 mem - Changed _ManagerTypeIDList to 11
**          06/09/2011 mem - Now calling EnableDisableAllManagers
**          01/30/2020 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    Call EnableDisableAllManagers (
        _managerTypeIDList := '11', 
        _managerNameList := '', 
        _enable := 0,
        _infoOnly := _infoOnly, 
        _message := _message,
        _returnCode := _returnCode);

END
$$;


ALTER PROCEDURE mc.disableanalysismanagers(_infoonly integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE disableanalysismanagers(_infoonly integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.disableanalysismanagers(_infoonly integer, INOUT _message text, INOUT _returncode text) IS 'DisableAnalysisManagers';

