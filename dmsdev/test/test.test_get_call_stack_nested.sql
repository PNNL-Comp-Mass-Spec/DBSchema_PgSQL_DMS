--
-- Name: test_get_call_stack_nested(integer); Type: FUNCTION; Schema: test; Owner: d3l243
--

CREATE OR REPLACE FUNCTION test.test_get_call_stack_nested(_recursiondepth integer DEFAULT 0) RETURNS TABLE(depth integer, schema_name text, object_name text, line_number integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT S.depth, S.schema_name, S.object_name, S.line_number
    FROM test.test_get_call_stack(_recursionDepth) AS S;
END;
$$;


ALTER FUNCTION test.test_get_call_stack_nested(_recursiondepth integer) OWNER TO d3l243;

