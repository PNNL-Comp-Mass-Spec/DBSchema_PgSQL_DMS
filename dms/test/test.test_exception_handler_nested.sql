--
-- Name: test_exception_handler_nested(text, boolean); Type: FUNCTION; Schema: test; Owner: d3l243
--

CREATE OR REPLACE FUNCTION test.test_exception_handler_nested(_divisor text, _useerrorhandler boolean DEFAULT true) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    _result numeric;
BEGIN
    _result := test.test_exception_handler(_divisor, _useerrorhandler);
    Return _result;
End
$$;


ALTER FUNCTION test.test_exception_handler_nested(_divisor text, _useerrorhandler boolean) OWNER TO d3l243;

