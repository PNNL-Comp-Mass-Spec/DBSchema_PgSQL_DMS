--
-- Name: test_get_call_stack_nested(integer); Type: FUNCTION; Schema: test; Owner: d3l243
--

CREATE OR REPLACE FUNCTION test.test_get_call_stack_nested(_recursiondepth integer DEFAULT 0) RETURNS TABLE(depth integer, schema_name text, object_name text, line_number integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Calls test_get_call_stack(), which uses GET DIAGNOSTICS to obtain the context, then uses get_call_stack() to convert the context to a call stack table
**
**  Arguments:
**    _recursionDepth       When 0, simply display the context; when non-zero, recursively call test.test_get_call_stack()
**
**  Example usage:
**      SELECT * FROM test.test_get_call_stack_nested(0);
**      SELECT * FROM test.test_get_call_stack_nested(1);
**      SELECT * FROM test.test_get_call_stack_nested(2);
**
**  Auth:   mem
**  Date:   08/24/2022 mem - Initial version
**
*****************************************************/
BEGIN
    RETURN QUERY
    SELECT S.depth, S.schema_name, S.object_name, S.line_number
    FROM test.test_get_call_stack(_recursionDepth) AS S;
END;
$$;


ALTER FUNCTION test.test_get_call_stack_nested(_recursiondepth integer) OWNER TO d3l243;

