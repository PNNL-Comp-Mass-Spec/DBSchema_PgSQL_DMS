--
-- Name: trim_whitespace(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trim_whitespace(_text text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Removes whitespace (including Cr, Lf, and tab) from the start and end of text
**
**      See also public.trim_whitespace_and_punctuation() which also removes periods, commas, semicolons,
**      single quotes, and double quotes from the start and end of the text
**
**  Return value: Trimmed text
**
**  Auth:   mem
**  Date:   07/01/2014 mem - Initial release
**          06/23/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved words
**          06/14/2023 mem - Rename from scrub_whitespace to trim_whitespace
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

        _currentLength := char_length(_newText);
    END LOOP;

    RETURN _newText;
END
$$;


ALTER FUNCTION public.trim_whitespace(_text text) OWNER TO d3l243;

--
-- Name: FUNCTION trim_whitespace(_text text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.trim_whitespace(_text text) IS 'TrimWhitespace';

