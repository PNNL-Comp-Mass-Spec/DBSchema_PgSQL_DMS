--
-- Name: test_harness2(text); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION mc.test_harness2(_managernamelist text) RETURNS TABLE(mgr_id integer, paramtypeid integer, value text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    _message text;
    _managerParamCount int;
    _paramTypeID int;
    _sqlstate text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN
    CREATE TEMP TABLE TmpManagerList (
        manager_name citext NOT NULL,
        mgr_id int NULL
    );

    CALL mc.parse_manager_name_list(_managerNameList, _removeUnknownManagers => 1, _message => _message);

    RAISE INFO '%', _message;

    SELECT param_id INTO _paramTypeID
    FROM mc.t_param_type
    WHERE param_name = 'ManagerErrorCleanupMode';

    RAISE info '%', _paramTypeID;

    RETURN query
    SELECT MgrListA.mgr_id, 0 AS test, MgrListA.manager_name::text
           FROM TmpManagerList MgrListA;

    -- Calling RETURN query again will append additional rows to the output table
    --
    RETURN query
    SELECT A.mgr_id, _paramTypeID, '0'
    FROM ( SELECT MgrListA.mgr_id
           FROM TmpManagerList MgrListA
         ) A
         LEFT OUTER JOIN
          ( SELECT MgrListB.mgr_id
            FROM TmpManagerList MgrListB
                 INNER JOIN mc.t_param_value PV
                   ON MgrListB.mgr_id = PV.mgr_id
            WHERE PV.type_id = _paramTypeID
         ) B
           ON A.mgr_id = B.mgr_id
    WHERE B.mgr_id IS NULL;

    DROP TABLE IF EXISTS TmpManagerList;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := 'Error calling parse_manager_name_list or updating data: ' || _exceptionMessage;

    RAISE Info '%', _message;
    RAISE Info 'Exception context; %', _exceptionContext;

    RAISE Exception '%, code %; see the output for context', _message, _sqlstate;

End
$$;


ALTER FUNCTION mc.test_harness2(_managernamelist text) OWNER TO d3l243;

