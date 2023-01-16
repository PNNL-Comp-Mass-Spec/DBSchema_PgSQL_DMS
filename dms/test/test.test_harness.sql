--
-- Name: test_harness(text); Type: FUNCTION; Schema: test; Owner: d3l243
--

CREATE OR REPLACE FUNCTION test.test_harness(_managernamelist text) RETURNS TABLE(manager_name text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    _managerNames text[];
    _message text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN

    _managerNames := ARRAY (
                        SELECT NameQ.manager_name
                        FROM mc.parse_manager_name_list(_managerNameList, _remove_unknown_managers => 0) NameQ
                     );

    RAISE INFO 'Manager count returned: %', array_length(_managerNames, 1);

    RETURN Query
    SELECT unnest( _managerNames );

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := 'Error calling parse_manager_name_list: ' || _exceptionMessage;

    RAISE Info '%', _message;
    RAISE Info 'Exception context; %', _exceptionContext;

    RAISE Exception '%, code %; see the output for context', _message, _sqlState;

End
$$;


ALTER FUNCTION test.test_harness(_managernamelist text) OWNER TO d3l243;

