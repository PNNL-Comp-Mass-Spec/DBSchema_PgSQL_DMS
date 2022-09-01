--
-- Name: test_exception_handler_nested(text, boolean); Type: FUNCTION; Schema: test; Owner: d3l243
--

CREATE OR REPLACE FUNCTION test.test_exception_handler_nested(_divisor text, _useerrorhandler boolean DEFAULT true) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Uses function test_exception_handler to divide 100 by _divisor and return the result
**      That function raises an exception if _divisor is not numeric
**      Query this function with _divisor => '0' to force a divide-by-zero error
**
**  Example usage:
**
**      SELECT test.test_exception_handler_nested('40', false);
**      SELECT test.test_exception_handler_nested('apple', false);
**      SELECT test.test_exception_handler_nested('apple', true);
**
**      SELECT * FROM public.t_log_entries WHERE entered > CURRENT_TIMESTAMP - Interval '1 hour';
**
**  Auth:   mem
**  Date:   08/24/2022 mem - Initial version
**
*****************************************************/

DECLARE
    _result numeric;
BEGIN
    _result := test.test_exception_handler(_divisor, _useerrorhandler);
    Return _result;
End
$$;


ALTER FUNCTION test.test_exception_handler_nested(_divisor text, _useerrorhandler boolean) OWNER TO d3l243;

