--
-- Name: test_get_function_name(boolean); Type: FUNCTION; Schema: test; Owner: d3l243
--

CREATE OR REPLACE FUNCTION test.test_get_function_name(_showdebug boolean DEFAULT false) RETURNS TABLE(description text, name text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    _functionName text;
BEGIN

    RETURN QUERY
    SELECT 'Name with arguments', *
    FROM get_current_function_name(true, _showDebug);

    RETURN QUERY
    SELECT 'Name only', *
    FROM get_current_function_name(false);

END;
$$;


ALTER FUNCTION test.test_get_function_name(_showdebug boolean) OWNER TO d3l243;

