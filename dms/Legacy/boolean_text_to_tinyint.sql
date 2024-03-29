--
-- Name: boolean_text_to_tinyint(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.boolean_text_to_tinyint(_booleantext text) RETURNS smallint
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
**          01/21/2024 mem - Change data type of argument _booleanText to text
**
*****************************************************/
DECLARE
    _value int := 0;
BEGIN

    _booleanText := Trim(Coalesce(_booleanText, ''));

    If _booleanText::citext IN ('Yes', 'Y', '1', 'True', 'T') Then
        _value := 1;
    End If;

    Return _value;
END
$$;


ALTER FUNCTION public.boolean_text_to_tinyint(_booleantext text) OWNER TO d3l243;

--
-- Name: FUNCTION boolean_text_to_tinyint(_booleantext text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.boolean_text_to_tinyint(_booleantext text) IS 'BooleanTextToTinyint';

