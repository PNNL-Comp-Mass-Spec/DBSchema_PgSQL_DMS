--
-- Name: test_get_procedure_name(boolean); Type: PROCEDURE; Schema: test; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE test.test_get_procedure_name(IN _showdebug boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
DECLARE
    _functionName text;
    _procedureName text;
BEGIN
    SELECT name
    INTO _functionName
    FROM test_get_function_name(_showDebug);

    RAISE INFO 'Calling name inside test_get_function_name(): %', _functionName;

    SELECT *
    INTO _procedureName
    FROM get_current_function_name(true, _showDebug => _showDebug);

    RAISE INFO 'Procedure name (with arguments):              %', _procedureName;

    SELECT *
    INTO _procedureName
    FROM get_current_function_name(false, _showDebug => _showDebug);

    RAISE INFO 'Procedure name (no arguments):                %', _procedureName;

END;
$$;


ALTER PROCEDURE test.test_get_procedure_name(IN _showdebug boolean) OWNER TO d3l243;

