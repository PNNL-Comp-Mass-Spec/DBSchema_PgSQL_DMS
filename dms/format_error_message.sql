--
-- Name: format_error_message(text, text, text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.format_error_message(_sqlstate text, _exceptionmessage text, _exceptiondetail text, _exceptioncontext text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Constructs and returns a formatted error message
**
**      Call this function after using GET STACKED DIAGNOSTICS
**
**  Arguments:
**    _sqlState                     SQL State
**    _exceptionMessage             Exception message
**    _exceptionDetail              Exception detail
**    _exceptionContext             Exception context, e.g. PL/pgSQL function test.test_exception_handler(text,boolean) line 35 at RAISE
**
**  Auth:   grk
**  Date:   04/16/2010 grk - Initial release
**          08/24/2022 mem - Ported to PostgreSQL
**
****************************************************/
DECLARE
    _schemaName text;
    _functionName text;
    _lineNumber int;
    _functionNameWithSchema text;
    _errorMessage text;
    _innerExceptionMessage text;
BEGIN

    SELECT schema_name, object_name, line_number
    INTO _schemaName, _functionName, _lineNumber
    FROM public.get_call_stack(_exceptionContext)
    ORDER BY depth DESC
    LIMIT 1;

    If FOUND Then
        If char_length(coalesce(_schemaName, '')) > 0 Then
            _functionNameWithSchema := format('%I.%I', _schemaName, _functionName);
        Else
            _functionNameWithSchema := _functionName;
        End If;
    Else
        _functionNameWithSchema := '<Unknown Function>';
    End If;

    _errorMessage := format('%s, state %s (%s, line %s)',
                        Coalesce(_exceptionMessage, 'Unknown error'),
                        Coalesce(_sqlState, '??'),
                        Coalesce(_functionNameWithSchema, '??'),
                        Coalesce(_lineNumber, 0));

    If char_length(Coalesce(_exceptionDetail, '')) > 0 Then
        _errorMessage := _errorMessage || ': ' || _exceptionDetail;
    End If;

    RETURN Coalesce(_errorMessage, '');

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _innerExceptionMessage = message_text;

    _errorMessage := format('Error formatting error message: %s; calling method exception: %s',
                            Coalesce(_innerExceptionMessage, '??'),
                            Coalesce(_exceptionMessage, '??'));

    RAISE Warning '%', _result;

    RETURN Coalesce(_errorMessage, '');
END
$$;


ALTER FUNCTION public.format_error_message(_sqlstate text, _exceptionmessage text, _exceptiondetail text, _exceptioncontext text) OWNER TO d3l243;

--
-- Name: FUNCTION format_error_message(_sqlstate text, _exceptionmessage text, _exceptiondetail text, _exceptioncontext text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.format_error_message(_sqlstate text, _exceptionmessage text, _exceptiondetail text, _exceptioncontext text) IS 'FormatErrorMessage';

