--
-- Name: test_get_function_info(text, boolean); Type: FUNCTION; Schema: test; Owner: d3l243
--

CREATE OR REPLACE FUNCTION test.test_get_function_info(_schemaname text DEFAULT ''::text, _showdebug boolean DEFAULT false) RETURNS TABLE(schema_name text, object_name text, argument_data_types text, name_with_schema text, object_signature text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    _functionName text;
BEGIN
    RETURN QUERY
    SELECT I.schema_name, I.object_name, I.argument_data_types, I.name_with_schema, I.object_signature
    FROM public.get_current_function_info(_schemaName, _showDebug) I;
END;
$$;


ALTER FUNCTION test.test_get_function_info(_schemaname text, _showdebug boolean) OWNER TO d3l243;

