--
-- Name: test_get_call_stack(integer); Type: FUNCTION; Schema: test; Owner: d3l243
--

CREATE OR REPLACE FUNCTION test.test_get_call_stack(_recursiondepth integer DEFAULT 0) RETURNS TABLE(depth integer, schema_name text, object_name text, line_number integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Uses GET DIAGNOSTICS to obtain the context, then uses get_call_stack() to convert the context to a call stack stable
**
**  Arguments:
**    _recursionDepth       When 0, simply display the context; when non-zero, recursively call this function
**
**  Example usage:
**
**      SELECT * FROM test.test_get_call_stack_nested(0);
**      SELECT * FROM test.test_get_call_stack_nested(1);
**      SELECT * FROM test.test_get_call_stack_nested(2);
**
**  Auth:   mem
**  Date:   08/24/2022 mem - Initial version
*****************************************************/
DECLARE
    _pgContext text;
BEGIN
    If Coalesce(_recursionDepth, 0) > 0 Then
        RETURN QUERY
        SELECT S.depth, S.schema_name, S.object_name, S.line_number
        FROM test.test_get_call_stack(_recursionDepth - 1) S;

        Return;
    End If;

    GET DIAGNOSTICS _pgContext = PG_CONTEXT;
    RAISE NOTICE 'Context: %', _pgContext;

    RETURN QUERY
    SELECT S.depth, S.schema_name, S.object_name, S.line_number
    FROM public.get_call_stack(_pgContext) AS S;
END;
$$;


ALTER FUNCTION test.test_get_call_stack(_recursiondepth integer) OWNER TO d3l243;

