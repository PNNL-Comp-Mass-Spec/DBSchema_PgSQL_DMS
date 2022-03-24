--
-- Name: disablesequestclusters(integer, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.disablesequestclusters(IN _infoonly integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Disables the Sequest Clusters
**
**  Auth:   mem
**  Date:   07/24/2008
**          10/09/2009 mem - Changed _ManagerTypeIDList to 11
**          01/30/2020 mem - Ported to PostgreSQL
**          03/23/2022 mem - Use mc schema when calling EnableDisableAllManagers
**
*****************************************************/
DECLARE

BEGIN

    Call mc.EnableDisableAllManagers (
        _managerTypeIDList := '11',
        _managerNameList := '%SeqCluster%',
        _enable := 0,
        _infoOnly := _infoOnly,
        _message := _message,
        _returnCode := _returnCode);

END
$$;


ALTER PROCEDURE mc.disablesequestclusters(IN _infoonly integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE disablesequestclusters(IN _infoonly integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.disablesequestclusters(IN _infoonly integer, INOUT _message text, INOUT _returncode text) IS 'DisableSequestClusters';

