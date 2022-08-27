--
-- Name: test_exception_handler(text, boolean); Type: FUNCTION; Schema: test; Owner: d3l243
--

CREATE OR REPLACE FUNCTION test.test_exception_handler(_divisor text, _useerrorhandler boolean DEFAULT true) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Divides 100 by _divisor and returns the result
**      Raises a exception if _divisor is not numeric
**      Call this method with _divisor => '0' to force a divide-by-zero error
**
**  Example usage:
**
**      SELECT test.test_exception_handler('40', false);
**      SELECT test.test_exception_handler('apple', false);
**      SELECT test.test_exception_handler('apple', true);
**
**      SELECT * FROM public.t_log_entries WHERE entered > CURRENT_TIMESTAMP - Interval '1 hour';
**
**  Auth:   mem
**  Date:   08/24/2022 mem - Initial version
**
*****************************************************/
DECLARE
    _currentLocation text;
    _divisorValue numeric;
    _result numeric;
    _message text;
    _sqlstate text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _currentLocation := 'Start';

    _useErrorHandler := Coalesce(_useErrorHandler, false);

    _currentLocation := 'Cast to numeric';

    _divisorValue = try_cast(_divisor, true, 0::numeric);

    If _divisorValue Is Null Then
        RAISE EXCEPTION 'Value is not numeric: %', Coalesce(_divisor, 'null');
    End If;

    _currentLocation := format('Divide 100 by %s', _divisorValue);

    _result := 100 / _divisorValue;

    Return _result;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState         = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionDetail  = pg_exception_detail,
            _exceptionContext = pg_exception_context;

    If _useErrorHandler Then
        RAISE INFO '_sqlState: %',         _sqlState;
        RAISE INFO '_exceptionMessage: %', _exceptionMessage;
        RAISE INFO '_exceptionDetail: %',  Coalesce(_exceptionDetail, '');
        RAISE INFO '_exceptionContext: %', Coalesce(_exceptionContext, '');

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _currentLocation, _logError => true);
    Else
        _message := format_error_message(_sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext);

        RAISE Warning '%', _message;
        RAISE INFO 'Context: %', _exceptionContext;

        -- Rollback any open transactions
        -- Note that PostgreSQL doesn't assign a transaction ID until a write operation occurs
        If Not pg_current_xact_id_if_assigned() Is Null Then
            ROLLBACK;
        End If;

        -- Uncomment to log
        -- Call public.post_log_entry ('Error', _message, 'test_exception_handler');
    End If;

    Return 0;
End
$$;


ALTER FUNCTION test.test_exception_handler(_divisor text, _useerrorhandler boolean) OWNER TO d3l243;

