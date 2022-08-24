--
-- Name: test_get_function_info(boolean); Type: FUNCTION; Schema: test; Owner: d3l243
--

CREATE OR REPLACE FUNCTION test.test_get_function_info(_showdebug boolean DEFAULT false) RETURNS TABLE(description text, schema_name text, object_name text, argument_data_types text, name_with_schema text, object_signature text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    _functionName text;
BEGIN
    RETURN QUERY
    SELECT 'Function info', I.schema_name, I.object_name, I.argument_data_types, I.name_with_schema, I.object_signature
    FROM public.get_current_function_info(_showDebug) I;
END;
$$;


ALTER FUNCTION test.test_get_function_info(_showdebug boolean) OWNER TO d3l243;

