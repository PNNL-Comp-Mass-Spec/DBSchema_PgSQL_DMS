--
-- Name: number_to_string(double precision, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--
-- Overload 1

CREATE OR REPLACE FUNCTION public.number_to_string(_value double precision, _digitsafterdecimal integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Convert the number to a string with the specified number of digits after the decimal
**
**  Auth:   mem
**  Date:   06/14/2022 mem - Initial version
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
BEGIN
    RETURN number_to_string(_value::numeric, _digitsAfterDecimal);
END
$$;


ALTER FUNCTION public.number_to_string(_value double precision, _digitsafterdecimal integer) OWNER TO d3l243;

--
-- Name: number_to_string(numeric, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--
-- Overload 2

CREATE OR REPLACE FUNCTION public.number_to_string(_value numeric, _digitsafterdecimal integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Convert the number to a string with the specified number of digits after the decimal
**
**  Auth:   mem
**  Date:   10/26/2017 mem - Initial version
**          10/27/2017 mem - Update while loop to reduce string updates
**                         - Change '-0' to '0'
**          06/14/2022 mem - Ported to PostgreSQL
**          11/24/2022 mem - Change _continue to a boolean
**          05/22/2023 mem - Capitalize reserved word
**          05/30/2023 mem - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _valueText text;
    _formatCode text;
    _continue boolean;
    _matchPos int;
BEGIN

    If _digitsAfterDecimal < 0 Then
        _digitsAfterDecimal := 0;
    End If;

    If Abs(_value) < 1e10 Then
        -- The number is less than 1e10; use Round()::text

        _valueText := Round(_value, _digitsAfterDecimal)::text;

        If strpos(_valueText, '.') > 0 Then
            -- Remove trailing zeroes after the decimal point
            _valueText := RTrim(_valueText, '0');

            If _valueText Like '%.' THEN
                _valueText := Left(_valueText, char_length(_valueText) - 1);
            End If;

        End If;
    Else
        -- For larger numbers, use to_char() with a format specifier
        -- For example, use '9.999EEEE' for three digits after the decimal point

        _formatCode := format('%s%s%s', '9.', REPEAT('9', _digitsAfterDecimal), 'EEEE');

        _valueText = Trim(to_char(_value, _formatCode));

        -- If the text has several zeroes before e+, remove the extra zeroes
        -- For example, change from '3.3000e+22' to '3.3e+22'

        _continue := true;

        WHILE _continue
        LOOP
            _matchPos := strpos(_valueText, '0e+');

            If _matchPos > 0 Then
                _valueText = Replace( _valueText, '0e+', 'e+');
            Else
                _continue := false;
            End If;
        END LOOP;

        -- If the text is of the form '3.e+22', change to '3e+22'
        _valueText = Replace(_valueText, '.e+', 'e+');
    End If;

    RETURN _valueText;
END
$$;


ALTER FUNCTION public.number_to_string(_value numeric, _digitsafterdecimal integer) OWNER TO d3l243;

--
-- Name: FUNCTION number_to_string(_value numeric, _digitsafterdecimal integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.number_to_string(_value numeric, _digitsafterdecimal integer) IS 'NumberToString';

