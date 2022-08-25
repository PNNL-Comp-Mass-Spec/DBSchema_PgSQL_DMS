--
-- Name: get_current_function_info(text, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_current_function_info(_schemaname text DEFAULT ''::text, _showdebug boolean DEFAULT false) RETURNS TABLE(schema_name text, object_name text, argument_data_types text, name_with_schema text, object_signature text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns information about the calling function or procedure,
**      including schema name, object name, and argument data types
**
**      This function uses "GET DIAGNOSTICS _context = PG_CONTEXT;" to determine the calling object's name
**      If the calling function or procedure is in a schema that is in the search path, the schema name will not be included in the context
**
**      Use argument _schemaName to explicitly define the schema of the calling function or procedure
**      If the context does not include a schema name, but _schemaName does have a name, column name_with_schema in the output table will include _schemaName
**      In contrast, column object_signature in the output table has a actual object signature extracted from the context and thus may not include the schema name
**
**      To view the search path use: SHOW search_path;
**
**  Arguments
**    _schemaName   Schema name to use if the context info does not include a schema name before the object name
**    _showDebug    When true, show the current context and RegEx match info
**
**  Example usage:
**
**      SELECT schema_name, object_name
**      INTO _schemaName, _objectName
**      FROM get_current_function_info();
**
**  Auth:   mem
**  Date:   08/24/2022 mem - Initial version
**
*****************************************************/
DECLARE
    _context text;
    _matches text[];
    _matchCount int;
    _objectSignature text;
    _objectNameAndSchema text;
    _dotPosition int;
    _objectName text;
    _objectArguments text;
    _charPos int;
BEGIN
    _schemaName := Trim(Coalesce(_schemaName, ''));
    _showDebug := Coalesce(_showDebug, false);

    GET DIAGNOSTICS _context = PG_CONTEXT;

    _matches = ARRAY (SELECT (regexp_matches(_context, 'function (.*?) line', 'g'))[1]);

    _matchCount = array_length(_matches, 1);

    If _showDebug Then
        RAISE INFO 'Context: %', _context;
        RAISE INFO 'regexp_matches array length: %', _matchCount;
    End If;

    If _matchCount > 1 Then
        -- When called from another function, the first match will be this function and the second match will be the calling function
        _objectSignature := _matches[2]::regprocedure::text;

    ElsIf _matchCount = 1 then
        -- There should be just one match only if the user directly called this function
        _objectSignature := _matches[1]::regprocedure::text;

    Else
        _objectSignature := 'Unknown calling function';
    End If;

    If _showDebug Then
        RAISE INFO 'Function signature: %', _objectSignature;
    End If;

    -- Extract out the arguments
    _charPos := Position('(' in _objectSignature);

    If _charPos > 1 Then
        _objectNameAndSchema := Trim(Left(_objectSignature, _charPos - 1));
        _objectArguments := Trim(Substring(_objectSignature, _charPos + 1));

        If _objectArguments Like '%)' Then
            -- Remove the trailing parenthesis
            _objectArguments = Left(_objectArguments, char_length(_objectArguments) - 1);
        End If;
    Else
        _objectNameAndSchema := _objectSignature;
        _objectArguments := '';
    End If;

    _dotPosition := Position('.' IN _objectNameAndSchema);
    If _dotPosition > 1 And _dotPosition < char_length(_objectNameAndSchema) Then
        _schemaName := Left(_objectNameAndSchema, _dotPosition - 1);
        _objectName := Substring(_objectNameAndSchema, _dotPosition + 1);
    Else
        _objectName := _objectNameAndSchema;

        If char_length(_schemaName) > 0 Then
            _objectNameAndSchema := format('%I.%s', _schemaName, _objectName);
        End If;
    End If;

    RETURN QUERY
    SELECT Coalesce(_schemaName, ''), _objectName, _objectArguments, _objectNameAndSchema, _objectSignature;
END;
$$;


ALTER FUNCTION public.get_current_function_info(_schemaname text, _showdebug boolean) OWNER TO d3l243;

