--
-- Name: test_get_procedure_info(text, boolean); Type: PROCEDURE; Schema: test; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE test.test_get_procedure_info(IN _schemaname text DEFAULT ''::text, IN _showdebug boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
DECLARE
    _functionInfo record;
    _procedureInfo record;
BEGIN
    SELECT schema_name, object_name, argument_data_types, name_with_schema, object_signature
    INTO _functionInfo
    FROM test.test_get_function_info(_schemaName, _showDebug);

    RAISE INFO 'Schema and name for function:  %', _functionInfo.name_with_schema;

    SELECT schema_name, object_name, argument_data_types, name_with_schema, object_signature
    INTO _procedureInfo
    FROM public.get_current_function_info(_schemaName, _showDebug);

    RAISE INFO 'Schema and name for procedure: %', _procedureInfo.name_with_schema;

    RAISE INFO 'Procedure signature: %', _procedureInfo.object_signature;
END;
$$;


ALTER PROCEDURE test.test_get_procedure_info(IN _schemaname text, IN _showdebug boolean) OWNER TO d3l243;

