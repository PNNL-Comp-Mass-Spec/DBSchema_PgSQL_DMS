--
-- Name: get_call_stack(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_call_stack(_pgcontext text) RETURNS TABLE(depth integer, schema_name text, object_name text, line_number integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Examines the context information from GET DIAGNOSTICS or GET STACKED DIAGNOSTICS to determine the call stack
**      Functions are shown in the order of most recently entered to the initial entry function
**
**  Example values for _pgContext:
**
**      From GET STACKED DIAGNOSTICS
**         PL/pgSQL function test.test_exception_handler(text,boolean) line 40 at RAISE
**         PL/pgSQL function test.test_exception_handler_nested(text,boolean) line 25 at assignment
**
**      From GET DIAGNOSTICS:
**          PL/pgSQL function test.test_get_call_stack(integer) line 32 at GET DIAGNOSTICS
**          SQL statement "SELECT S.depth, S.schema_name, S.object_name, S.line_number
**              FROM test.test_get_call_stack(_recursionDepth - 1) S"
**          PL/pgSQL function test.test_get_call_stack(integer) line 25 at RETURN QUERY
**          SQL statement "SELECT S.depth, S.schema_name, S.object_name, S.line_number
**              FROM test.test_get_call_stack(_recursionDepth) AS S"
**          PL/pgSQL function test.test_get_call_stack_nested(integer) line 3 at RETURN QUERY
**
**      Queries used to obtain the above example context:
**          SELECT test.test_exception_handler_nested('apple', false);
**          SELECT * FROM test.test_get_call_stack_nested(1);
**
**  Auth:   mem
**  Date:   08/24/2022 mem - Initial release
**          08/31/2022 mem - Update comments
**          05/22/2023 mem - Update whitespace
**          05/30/2023 mem - Use format() for string concatenation
**
****************************************************/
DECLARE
    _callStack text[][];            -- 2D array, columns: depth, schema_name, object_name, and line_number
    _matches text[];
    _matchCount int;
    _iteration int;
    _functionNameAndLineNumber text;
    _startPosition int;
    _dotPosition int;
    _subcontext text;
    _functionNameAndSchema text;
    _functionName text;
    _schemaName text;
    _lineNumber text;
    _stackRow text[];
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _errorMessage text;
BEGIN
    -- Initialize an empty array
    _callStack := array[]::text[];

    _matches = ARRAY (SELECT regexp_matches(_pgContext, 'function .*? line \d+', 'g'));
    _matchCount = Coalesce(array_length(_matches, 1), 0);

    FOR _iteration IN 1 .. _matchCount
    LOOP

        -- Because we used .*? above to specify lazy matching, \d+ will only match the first number in the line number (because the RegEx as a whole is lazy, aka non-greedy)

        -- In theory we could work around that limitation using an expression like '(?:(function .*?) (line \d+)){1,1}'
        -- In practice, this does not work
        -- Instead, extract the function name and line number from _pgContext, then extract the complete line number

        -- regexp_matches returns a set of arrays, so must use two sets of square brackets to extract the match
        _functionNameAndLineNumber := _matches[_iteration][1];

        _startPosition := Position(_functionNameAndLineNumber IN _pgContext);

        _subcontext := Substring(_pgContext, _startPosition);

        -- Note that the function name will include the schema if not in the public schema
        _functionNameAndSchema := (regexp_match(_subcontext, 'function ([^(]+)' ))[1];

        _dotPosition := Position('.' IN _functionNameAndSchema);
        If _dotPosition > 1 And _dotPosition < char_length(_functionNameAndSchema) Then
            _schemaName   := Left(_functionNameAndSchema, _dotPosition - 1);
            _functionName := Substring(_functionNameAndSchema, _dotPosition + 1);
        Else
            _functionName := _functionNameAndSchema;
            _schemaName   := '';
        End If;

        _lineNumber := (regexp_match(_subcontext, 'line (\d+)' ))[1];

        -- Append to the 2D array
        _callStack := _callStack || ARRAY[[_iteration::text, _schemaName, _functionName, Coalesce(_lineNumber, '0')]];

    END LOOP;

    If Coalesce(array_length(_callStack, 1), 0) = 0 Then
        _callStack := _callStack || ARRAY[['1', '', 'Undefined_Function', '0']];
    End If;

    FOREACH _stackRow SLICE 1 IN ARRAY _callStack
    LOOP
        RETURN QUERY
        SELECT try_cast(_stackRow[1], 0), _stackRow[2], _stackRow[3], try_cast(_stackRow[4], 0);
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState         = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionDetail  = pg_exception_detail,
            _exceptionContext = pg_exception_context;

    -- Manually format the error message
    -- (do not call local_error_handler or use format_error_message since those functions reference this function)

    _errorMessage := format('Error determining the call stack, %s, state %s',
                            Coalesce(_exceptionMessage, 'Unknown error'),
                            Coalesce(_sqlState, '??'));

    If char_length(Coalesce(_exceptionDetail, '')) > 0 Then
        _errorMessage := format('%s: %s', _errorMessage, _exceptionDetail);
    End If;

    RAISE WARNING '%', Coalesce(_errorMessage, '??');

    If Coalesce(array_length(_callStack, 1), 0) = 0 Then
        _callStack := _callStack || ARRAY[['1', '', 'Undefined_Function', '0']];
    End If;

    FOREACH _stackRow SLICE 1 IN ARRAY _callStack
    LOOP
        RETURN QUERY
        SELECT try_cast(_stackRow[1], 0), _stackRow[2], _stackRow[3], try_cast(_stackRow[4], 0);
    END LOOP;
END;
$$;


ALTER FUNCTION public.get_call_stack(_pgcontext text) OWNER TO d3l243;

