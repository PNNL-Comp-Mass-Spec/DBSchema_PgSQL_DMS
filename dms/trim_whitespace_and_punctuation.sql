--
-- Name: trim_whitespace_and_punctuation(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trim_whitespace_and_punctuation(_text text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Remove whitespace (including Cr, Lf, and tab) plus punctuation from the start and end of text
**      Punctuation characters: period, comma, semicolon, single quote, or double quote
**
**      See also public.trim_whitespace()
**
**  Returns:
**      Trimmed text
**
**  Auth:   mem
**  Date:   09/11/2020 mem - Initial release (modelled after UDF ScrubWhitespace)
**          06/23/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
DECLARE
    _newText text;
    _previousLength int;
    _currentLength int;
BEGIN
    _newText := Trim(Coalesce(_text, ''));

    _previousLength = 0;
    _currentLength := char_length(_newText);

    WHILE _currentLength > 0 And _currentLength <> _previousLength
    LOOP
        _previousLength = _currentLength;

        _newText := Trim(_newText);
        _newText := Trim(_newText, chr(10));    -- CR
        _newText := Trim(_newText, chr(13));    -- LF
        _newText := Trim(_newText, chr(9));     -- Tab

        _newText := Trim(_newText, '.');
        _newText := Trim(_newText, ',');
        _newText := Trim(_newText, ';');
        _newText := Trim(_newText, '''');
        _newText := Trim(_newText, '"');

        _currentLength := char_length(_newText);
    END LOOP;

    RETURN _newText;
END
$$;


ALTER FUNCTION public.trim_whitespace_and_punctuation(_text text) OWNER TO d3l243;

--
-- Name: FUNCTION trim_whitespace_and_punctuation(_text text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.trim_whitespace_and_punctuation(_text text) IS 'TrimWhitespaceAndPunctuation';

