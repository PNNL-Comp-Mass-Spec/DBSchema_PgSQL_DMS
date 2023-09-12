--
-- Name: get_current_function_info(text, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_current_function_info(_schemaname text DEFAULT '<auto>'::text, _showdebug boolean DEFAULT false) RETURNS TABLE(schema_name text, object_name text, argument_data_types text, name_with_schema text, object_signature text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns information about the calling function or procedure,
**      including schema name, object name, and argument data types
**
**      This function uses "GET DIAGNOSTICS _context = PG_CONTEXT;" to determine the calling object's name
**
**      If the calling function or procedure is in a schema that is in the search path,
**      the schema name will not be included in the context. The _schemaName argument
**      therefore defaults to '<auto>', which instructs this function to auto-determine the schema name
**      using system catalog views if the schema name is not included in the context. Alternatively, the
**      calling method can use the _schemaName argument to explicitly define the schema name to use.
**
**      If the context does not include a schema name, but the schema name could be auto determined
**      (or _schemaName was explicitly defined), columns schema_name and name_with_schema in the
**      returned table will include the schema name. In contrast, column object_signature has the
**      object signature extracted from the context and thus may not include the schema name.
**
**      To view the search path use: SHOW search_path;
**
**  Arguments
**    _schemaName   Schema name to use if the context info does not include a schema name before the object name
*                   Use '<auto>' or '<lookup>' to auto-determine the schema name for the object, if empty in the context
**    _showDebug    When true, show the current context and RegEx match info
**
**  Example usage:
**
**      SELECT schema_name, object_name
**      INTO _schemaName, _objectName
**      FROM get_current_function_info();
**
**      SELECT *
**      INTO _schemaName, _objectName
**      FROM get_current_function_info('<auto>', true);
**
**      SELECT *
**      INTO _schemaName, _objectName
**      FROM get_current_function_info('cap', true);
**
**  Auth:   mem
**  Date:   08/24/2022 mem - Initial version
**          09/01/2022 mem - Auto-determine the schema name if the context does not include a schema name and _schemaName is '<auto>' or '<lookup>'
**          05/31/2023 mem - Add support for calling this function from an anonymous code block (DO ... BEGIN ... END)
**          07/26/2023 mem - Move "Not" keyword to before the field name
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/11/2023 mem - Adjust capitalization of keywords
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
    _schemaFromQuery text;
BEGIN
    _schemaName := Trim(Coalesce(_schemaName, ''));
    _showDebug := Coalesce(_showDebug, false);

    GET DIAGNOSTICS _context = PG_CONTEXT;

    -- Example context:
    -- PL/pgSQL function test.test_get_call_stack(integer) line 32 at GET DIAGNOSTICS

    _matches = ARRAY (SELECT (regexp_matches(_context, 'function (.*?) line', 'g'))[1]);

    _matchCount = array_length(_matches, 1);

    If _showDebug Then
        RAISE INFO E'Context: \n%', _context;
        RAISE INFO 'regexp_matches array length: %', _matchCount;
    End If;

    If _matchCount > 1 Then
        -- When called from another function, the first match will be this function and the second match will be the calling function

        If Position('(' In _matches[2]::text) > 0 Then
            _objectSignature := _matches[2]::regprocedure::text;
        Else
            -- Most likely get_current_function() was called from an anonymous code block, and _context contains text of the form "function inline_code_block line 39"
            -- Cannot cast to type "regprocedure" since that cast expects to find a pair of parentheses
            _objectSignature := _matches[2]::text;
        End If;

    ElsIf _matchCount = 1 Then
        -- There should be just one match only if the user directly called this function
        _objectSignature := _matches[1]::regprocedure::text;

    Else
        _objectSignature := 'Unknown calling function';
    End If;

    If _showDebug Then
        RAISE INFO 'Function signature: %', _objectSignature;
    End If;

    -- Extract out the arguments
    _charPos := Position('(' In _objectSignature);

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

    _dotPosition := Position('.' In _objectNameAndSchema);
    If _dotPosition > 1 And _dotPosition < char_length(_objectNameAndSchema) Then
        _schemaName := Left(_objectNameAndSchema, _dotPosition - 1);
        _objectName := Substring(_objectNameAndSchema, _dotPosition + 1);
    Else
        _objectName := _objectNameAndSchema;

        If Lower(_schemaName) In ('<auto>', '<lookup>') Then

            -- Lookup the schema name, choosing the first schema found if multiple functions match _objectName
            SELECT n.nspname AS schema
            INTO _schemaFromQuery
            FROM pg_proc p
                INNER JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE NOT n.nspname IN ('pg_catalog', 'information_schema') AND
                  p.proname = _objectName
            ORDER BY n.nspname
            LIMIT 1;

            If Not Found Then
                If _showDebug Then
                    RAISE INFO 'Unable to auto-determine the schema for %; not found in system catalog pg_proc', _objectName;
                End If;

                _schemaName := '';
            Else
                If _showDebug Then
                    RAISE INFO 'Schema for % is %', _objectName, _schemaFromQuery;
                End If;

                _schemaName := _schemaFromQuery;
            End If;

            -- The following query shows functions with identical names in separate schema
            -- Examples include:
            --   cap.consolidate_log_messages         and sw.consolidate_log_messages
            --   cap.get_task_script_dot_format_table and sw.get_task_script_dot_format_table
            --   cap.get_uri_path_id                  and dpkg.get_uri_path_id
            --   public.manage_job_execution          and sw.manage_job_execution
            --   cap.store_myemsl_upload_stats        and dpkg.store_myemsl_upload_stats
            --   cap.store_quameter_results           and public.store_quameter_results

            /*
                SELECT p.proname as Function, min(n.nspname) as First_Schema, max(n.nspname) as Last_Schema
                FROM pg_proc p
                    INNER JOIN pg_namespace n ON p.pronamespace = n.oid
                WHERE NOT n.nspname IN ('pg_catalog', 'information_schema')
                GROUP BY p.proname
                HAVING count(*) > 1 and min(n.nspname) <> max(n.nspname)
                ORDER BY p.proname
            */

        End If;

        If char_length(_schemaName) > 0 Then
            _objectNameAndSchema := format('%I.%s', _schemaName, _objectName);
        End If;
    End If;

    RETURN QUERY
    SELECT Coalesce(_schemaName, ''), _objectName, _objectArguments, _objectNameAndSchema, _objectSignature;
END;
$$;


ALTER FUNCTION public.get_current_function_info(_schemaname text, _showdebug boolean) OWNER TO d3l243;

