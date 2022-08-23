--
-- Name: get_current_function_name(boolean, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_current_function_name(_includearguments boolean DEFAULT false, _showdebug boolean DEFAULT false) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns the name of the calling function or procedure
**
**  Arguments
**    _includeArguments     When true, include the data types of the function arguments; otherwise, only return the calling method's name
**    _showDebug            When true, show current context and the number of matches found via the RegEx
**
**  Auth:   mem
**  Date:   08/23/2022 mem - Initial version
**
*****************************************************/
DECLARE
    _context text;
    _matches text[];
    _matchCount int;
    _functionSignature text;
    _charPos int;
BEGIN
    GET DIAGNOSTICS _context = PG_CONTEXT;

    _matches = ARRAY (SELECT (regexp_matches(_context, 'function (.*?) line', 'g'))[1]);

    _matchCount = array_length(_matches, 1);

    If Coalesce(_showDebug, false) Then
        RAISE INFO 'Context: %', _context;
        RAISE INFO 'regexp_matches array length: %', _matchCount;
    End If;

    If _matchCount > 1 Then
        _functionSignature := _matches[2]::regprocedure::text;
    ElsIf _matchCount = 1 then
        _functionSignature := _matches[1]::regprocedure::text;
    Else
        RETURN 'Unknown calling function';
    End If;

    _charPos := Position('(' in _functionSignature);

    If Coalesce(_includeArguments, true) Or _charPos <= 1 Then
        RETURN _functionSignature;
    Else
        RETURN Left(_functionSignature, _charPos - 1);
    End If;
END;
$$;


ALTER FUNCTION public.get_current_function_name(_includearguments boolean, _showdebug boolean) OWNER TO d3l243;

