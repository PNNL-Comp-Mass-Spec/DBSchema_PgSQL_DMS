--
-- Name: boolean_text_to_tinyint(public.citext); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.boolean_text_to_tinyint(_booleantext public.citext) RETURNS smallint
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns 1 if _booleanText is Yes, Y, 1, True, or T
**      Otherwise, returns 0
**
**  Auth:   mem
**  Date:   05/28/2019 mem - Initial version
**          06/17/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
DECLARE
    _value int := 0;
BEGIN

    _booleanText := Trim(Coalesce(_booleanText, ''));

    If _booleanText = 'Yes' Or _booleanText = 'Y' OR _booleanText = '1' Or _booleanText = 'True' Or _booleanText = 'T' Then
        _value := 1;
    End If;

    RETURN _value;
END
$$;


ALTER FUNCTION public.boolean_text_to_tinyint(_booleantext public.citext) OWNER TO d3l243;

--
-- Name: FUNCTION boolean_text_to_tinyint(_booleantext public.citext); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.boolean_text_to_tinyint(_booleantext public.citext) IS 'BooleanTextToTinyint';

