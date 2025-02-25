--
-- Name: sum_values(integer[]); Type: FUNCTION; Schema: test; Owner: d3l243
--

CREATE OR REPLACE FUNCTION test.sum_values(_values integer[]) RETURNS TABLE(total integer, count_positive integer, count_negative integer, count_zero integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Sums the integers in the array parameter
**      Also counts the number of integers that are positive, negative, or zero
**
**  Arguments:
**    _values       Array of integers
**
**  Example usage:
**      SELECT * FROM test.sum_values('{10, 15, -5, -6, 0}');
**      SELECT * FROM test.sum_values(ARRAY [1, 10, 15, 20, 0, -5, 0, -6, -7]);
**
**  Auth:   mem
**  Date:   02/24/2025 mem - Initial version
**
*****************************************************/
DECLARE
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _message text;
BEGIN
    BEGIN
        -----------------------------------------------------------
        -- Compute the sum of the values in the array
        -- Also count the number of values that are positive, negative, or zero
        -----------------------------------------------------------

        RETURN QUERY
        SELECT SUM(Values)::int AS Total,
               (COUNT(Values) FILTER (WHERE Values > 0))::int AS CountPositive,
               (COUNT(Values) FILTER (WHERE Values < 0))::int AS CountNegative,
               (COUNT(Values) FILTER (WHERE Values = 0))::int AS CountZero
        FROM (SELECT Unnest(_values) AS Values
             ) SourceQ;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        RAISE WARNING '%', _message;
    END;
END
$$;


ALTER FUNCTION test.sum_values(_values integer[]) OWNER TO d3l243;

