--
-- Name: scrub_whitespace(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.scrub_whitespace(_text text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Removes whitespace (including Cr, Lf, and tab) from the start and end of text
**
**  Return value: error message
**
**  Auth:   mem
**  Date:   07/01/2014 mem - Initial release
**          06/23/2022 mem - Ported to PostgreSQL
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

    While _currentLength > 0 And _currentLength <> _previousLength Loop
        _previousLength = _currentLength;

        _newText := Trim(_newText);
        _newText := Trim(_newText, Chr(10));    -- CR
        _newText := Trim(_newText, Chr(13));    -- LF
        _newText := Trim(_newText, Chr(9));     -- Tab

        _currentLength := char_length(_newText);
    End Loop;

    Return _newText;
END
$$;


ALTER FUNCTION public.scrub_whitespace(_text text) OWNER TO d3l243;

--
-- Name: FUNCTION scrub_whitespace(_text text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.scrub_whitespace(_text text) IS 'ScrubWhitespace';

