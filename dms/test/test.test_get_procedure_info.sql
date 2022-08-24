--
-- Name: test_get_procedure_info(boolean); Type: PROCEDURE; Schema: test; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE test.test_get_procedure_info(IN _showdebug boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
DECLARE
    _objectInfo record;
BEGIN
    SELECT schema_name, object_name, argument_data_types, name_with_schema, object_signature
    INTO _objectInfo
    FROM test.test_get_function_info(_showDebug);

    RAISE INFO 'Schema and name for function:  %', _objectInfo.name_with_schema;

    SELECT schema_name, object_name, argument_data_types, name_with_schema, object_signature
    INTO _objectInfo
    FROM public.get_current_function_info(_showDebug);

    RAISE INFO 'Schema and name for procedure: %', _objectInfo.name_with_schema;

    RAISE INFO 'Procedure signature: %', _objectInfo.object_signature;
END;
$$;


ALTER PROCEDURE test.test_get_procedure_info(IN _showdebug boolean) OWNER TO d3l243;

