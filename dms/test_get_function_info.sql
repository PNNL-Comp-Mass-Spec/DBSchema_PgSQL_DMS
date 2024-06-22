--
-- Name: test_get_function_info(text, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.test_get_function_info(_schemaname text DEFAULT '<auto>'::text, _showdebug boolean DEFAULT false) RETURNS TABLE(schema_name text, object_name text, argument_data_types text, name_with_schema text, object_signature text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Test using public.get_current_function_info() to auto-determine the schema and name of this function
**
**  Arguments:
**    _schemaName   Schema name to use if the context info does not include a schema name before the object name
**                  Use '<auto>' or '<lookup>' to auto-determine the schema name for the object, if empty in the context
**    _showDebug    When true, show debug info
**
**  Example usage:
**      SELECT *
**      FROM test_get_function_info();
**
**      SELECT *
**      FROM test_get_function_info('<auto>', true);
**
**      SELECT *
**      FROM test_get_function_info('public', true);
**
**      SELECT *
**      FROM test_get_function_info('sw', true);
**
**  Auth:   mem
**  Date:   08/24/2022 mem - Initial version
**          09/01/2022 mem - Change the default value for _schemaName to '<auto>'
**          06/21/2024 mem - Add a blank line to the output window
**
*****************************************************/
BEGIN
    RAISE INFO '';

    RETURN QUERY
    SELECT I.schema_name, I.object_name, I.argument_data_types, I.name_with_schema, I.object_signature
    FROM public.get_current_function_info(_schemaName, _showDebug) I;
END;
$$;


ALTER FUNCTION public.test_get_function_info(_schemaname text, _showdebug boolean) OWNER TO d3l243;

