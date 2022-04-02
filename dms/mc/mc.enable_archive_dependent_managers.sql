--
-- Name: enable_archive_dependent_managers(integer, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.enable_archive_dependent_managers(IN _infoonly integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Enables managers that rely on MyEMSL
**
**  Auth:   mem
**  Date:   06/09/2011 mem - Initial Version
**          02/05/2020 mem - Ported to PostgreSQL
**          03/23/2022 mem - Use mc schema when calling EnableDisableAllManagers
**
*****************************************************/
DECLARE

BEGIN

    -- Enable Space managers (type 8)
    Call mc.EnableDisableAllManagers (
        _managerTypeIDList := '8',
        _managerNameList := 'All',
        _enable := 1,
        _infoOnly := _infoOnly,
        _message := _message,
        _returnCode := _returnCode);

END
$$;


ALTER PROCEDURE mc.enable_archive_dependent_managers(IN _infoonly integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE enable_archive_dependent_managers(IN _infoonly integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.enable_archive_dependent_managers(IN _infoonly integer, INOUT _message text, INOUT _returncode text) IS 'EnableArchiveDependentManagers';

