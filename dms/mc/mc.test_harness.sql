--
-- Name: test_harness(text); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION mc.test_harness(_managernamelist text) RETURNS TABLE(manager_name text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    _message TEXT;
    _sqlstate text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN
    CREATE TEMP TABLE TmpManagerList (
        manager_name text NOT NULL
     );

    CALL mc.parse_manager_name_list(_managerNameList, _removeUnknownManagers => 0, _message => _message);

    RAISE INFO '%', _message;

    RETURN Query
    SELECT * FROM TmpManagerList;

    DROP TABLE tmpManagerList;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := 'Error calling parse_delimited_list: ' || _exceptionMessage;

    RAISE Info '%', _message;
    RAISE Info 'Exception context; %', _exceptionContext;

    RAISE Exception '%, code %; see the output for context', _message, _sqlstate;

End
$$;


ALTER FUNCTION mc.test_harness(_managernamelist text) OWNER TO d3l243;

