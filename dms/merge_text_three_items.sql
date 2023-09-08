--
-- Name: merge_text_three_items(text, text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.merge_text_three_items(_text1 text, _text2 text, _text3 text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**  Desc:
**      Concatenates _text1 and _text2 using a semicolon (but, if identical strings, just use _text1)
**
**      Next, concatenates _text3, provided it does not match _text1 or_text2
**
**  Auth:   mem
**  Date:   08/03/2007
**          06/23/2022 mem - Ported to PostgreSQL
**          05/30/2023 mem - Use format() for string concatenation
**          09/08/2023 mem - Adjust capitalization of keywords
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
            If char_length(_combinedText) > 0 Then
                _combinedText := format('%s; %s', _combinedText, _text3);
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

