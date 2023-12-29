--
-- Name: merge_text(text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.merge_text(_text1 text, _text2 text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Concatenate _text1 and _text2 using a semicolon
**
**      However, if the two variables have identical strings, only returns _text1
**
**  Auth:   mem
**  Date:   08/03/2007
**          06/23/2022 mem - Ported to PostgreSQL
**          05/30/2023 mem - Use format() for string concatenation
**          12/09/2023 mem - Use append_to_text() to append the strings
**
*****************************************************/
DECLARE
    _combinedText text;
BEGIN
    _combinedText := Trim(Coalesce(_text1, ''));
    _text2        := Trim(Coalesce(_text2, ''));

    If char_length(_text2) > 0 Then
        If _combinedText <> _text2 Then
            If char_length(_combinedText) > 0 Then
                _combinedText := append_to_text(_combinedText, _text2, _delimiter => '; ');
            Else
                _combinedText := _text2;
            End If;
        End If;
    End If;

    RETURN  _combinedText;
END
$$;


ALTER FUNCTION public.merge_text(_text1 text, _text2 text) OWNER TO d3l243;

--
-- Name: FUNCTION merge_text(_text1 text, _text2 text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.merge_text(_text1 text, _text2 text) IS 'MergeText';

