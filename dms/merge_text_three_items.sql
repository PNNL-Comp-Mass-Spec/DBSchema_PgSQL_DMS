--
-- Name: merge_text_three_items(text, text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.merge_text_three_items(_text1 text, _text2 text, _text3 text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Concatenate _text1 and _text2 using a semicolon (but, if identical strings, just use _text1)
**
**      Next, concatenate _text3, provided it does not match _text1 or_text2
**
**  Arguments:
**    _text1    First string
**    _text2    Second string
**    _text3    Third string
**
**  Auth:   mem
**  Date:   08/03/2007
**          06/23/2022 mem - Ported to PostgreSQL
**          05/30/2023 mem - Use format() for string concatenation
**          09/08/2023 mem - Adjust capitalization of keywords
**          12/09/2023 mem - Use append_to_text() to append the strings
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**
*****************************************************/
DECLARE
    _combinedText text;
BEGIN
    _text1 := Trim(Coalesce(_text1, ''));
    _text2 := Trim(Coalesce(_text2, ''));
    _text3 := Trim(Coalesce(_text3, ''));

    _combinedText := merge_text(_text1, _text2);

    If char_length(_text3) > 0 Then
        If _text1 <> _text3 And _text2 <> _text3 Then
            If _combinedText <> '' Then
                _combinedText := append_to_text(_combinedText, _text3, _delimiter => '; ');
            Else
                _combinedText := _text3;
            End If;
        End If;
    End If;

    RETURN _combinedText;
END
$$;


ALTER FUNCTION public.merge_text_three_items(_text1 text, _text2 text, _text3 text) OWNER TO d3l243;

--
-- Name: FUNCTION merge_text_three_items(_text1 text, _text2 text, _text3 text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.merge_text_three_items(_text1 text, _text2 text, _text3 text) IS 'MergeTextThreeItems';

