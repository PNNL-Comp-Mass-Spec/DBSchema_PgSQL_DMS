--
-- Name: test_harness2(text); Type: FUNCTION; Schema: test; Owner: d3l243
--

CREATE OR REPLACE FUNCTION test.test_harness2(_managernamelist text) RETURNS TABLE(mgr_id integer, mgr_name public.citext, param_type_id integer, value public.citext)
    LANGUAGE plpgsql
    AS $$
DECLARE
    _message text;
    _managerParamCount int;
    _paramTypeID int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN
    CREATE TEMP TABLE TmpManagerList (
        manager_name citext NOT NULL,
        mgr_id int NULL
    );

    INSERT INTO TmpManagerList (manager_name)
    SELECT manager_name
    FROM mc.parse_manager_name_list(_managerNameList, _remove_unknown_managers => 0);

    UPDATE TmpManagerList
    SET mgr_id = M.mgr_id
    FROM mc.t_mgrs M
    WHERE M.mgr_name = TmpManagerList.manager_name;

    SELECT pt.param_type_id
    INTO _paramTypeID
    FROM mc.t_param_type pt
    WHERE pt.param_name = 'ManagerErrorCleanupMode';

    RAISE INFO 'ManagerErrorCleanupMode param type ID: %', _paramTypeID;

    RETURN query
    SELECT M.mgr_id, M.manager_name, 0 AS param_type_id, ''::citext AS value
    FROM TmpManagerList M;

    -- Calling RETURN query again will append additional rows to the output table

    RETURN query
    SELECT M.mgr_id, M.manager_name, PV.param_type_id, PV.value
    FROM TmpManagerList M
         INNER JOIN mc.t_param_value PV
           ON M.mgr_id = PV.mgr_id
    WHERE PV.param_type_id = _paramTypeID;

    DROP TABLE TmpManagerList;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := format('Error calling parse_manager_name_list or updating data: %s', _exceptionMessage);

    RAISE INFO '%', _message;
    RAISE INFO 'Exception context; %', _exceptionContext;

    RAISE Exception '%, code %; see the output for context', _message, _sqlState;

    DROP TABLE IF EXISTS TmpManagerList;

End
$$;


ALTER FUNCTION test.test_harness2(_managernamelist text) OWNER TO d3l243;

