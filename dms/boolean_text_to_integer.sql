--
-- Name: boolean_text_to_integer(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.boolean_text_to_integer(_booleantext text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return 1 if _booleanText is Yes, Y, 1, True, or T
**      Otherwise, return 0
**
**  Arguments:
**    _booleanText      Boolean value, as text: 'Yes', 'Y', '1', 'True', 'T'
**
**  Auth:   mem
**  Date:   05/28/2019 mem - Initial version
**          06/17/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**          09/08/2023 mem - Adjust capitalization of keywords
**          10/05/2023 mem - Rename function to boolean_text_to_integer and return an integer instead of a smallint
**
*****************************************************/
DECLARE
    _value int;
BEGIN

    _booleanText := Trim(Coalesce(_booleanText, ''));

    If _booleanText::citext IN ('Yes', 'Y', '1', 'True', 'T') Then
        _value := 1;
    Else
        _value := 0;
    End If;

    RETURN _value;
END
$$;


ALTER FUNCTION public.boolean_text_to_integer(_booleantext text) OWNER TO d3l243;

--
-- Name: FUNCTION boolean_text_to_integer(_booleantext text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.boolean_text_to_integer(_booleantext text) IS 'BooleanTextToInteger or BooleanTextToTinyint';

