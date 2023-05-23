--
-- Name: replace_character_codes(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.replace_character_codes(_text text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Replaces HTML character codes with punctuation marks
**      Uses a case sensitive search for:
**        &quot;    (double quote)
**        &#34;     (double quote, via numeric ID)
**        &apos;    (single quote, aka apostrophe)
**        &amp;     (ampersand)
**
**  Return value: Updated text
**
**  Arguments:
**    _text   Text to update
**
**  Auth:   mem
**  Date:   02/25/2021 mem - Initial version
**          06/23/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
BEGIN
    _text := Coalesce(_text, '');

    If _text LIKE '%&quot;%' Then
        _text := Replace(_text, '&quot;', '"');
    End If;

    If _text LIKE '%&#34;%' Then
        _text := Replace(_text, '&#34;', '"');
    End If;

    If _text LIKE '%&apos;%' Then
        _text := Replace(_text, '&apos;', '''');
    End If;

    If _text LIKE '%&amp;%' Then
        _text := Replace(_text, '&amp;', '&');
    End If;

    RETURN _text;
END
$$;


ALTER FUNCTION public.replace_character_codes(_text text) OWNER TO d3l243;

--
-- Name: FUNCTION replace_character_codes(_text text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.replace_character_codes(_text text) IS 'ReplaceCharacterCodes';

