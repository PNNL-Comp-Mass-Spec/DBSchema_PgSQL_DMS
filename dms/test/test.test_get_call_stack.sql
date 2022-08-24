--
-- Name: test_get_call_stack(integer); Type: FUNCTION; Schema: test; Owner: d3l243
--

CREATE OR REPLACE FUNCTION test.test_get_call_stack(_recursiondepth integer DEFAULT 0) RETURNS TABLE(depth integer, schema_name text, object_name text, line_number integer)
    LANGUAGE plpgsql
    AS $$
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

