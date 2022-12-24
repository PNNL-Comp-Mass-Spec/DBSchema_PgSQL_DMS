--
-- Name: enablearchivedependentmanagers(integer, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.enablearchivedependentmanagers(IN _infoonly integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Enables managers that rely on MyEMSL
**
**  Auth:   mem
**  Date:   06/09/2011 mem - Initial Version
**          02/05/2020 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN

    -- Enable Space managers (type 8)
    Call EnableDisableAllManagers (
        _managerTypeIDList := '8',
        _managerNameList := 'All',
        _enable := 1,
        _infoOnly := _infoOnly,
        _message := _message,
        _returnCode := _returnCode);

END
$$;


ALTER PROCEDURE mc.enablearchivedependentmanagers(IN _infoonly integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE enablearchivedependentmanagers(IN _infoonly integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.enablearchivedependentmanagers(IN _infoonly integer, INOUT _message text, INOUT _returncode text) IS 'EnableArchiveDependentManagers';

