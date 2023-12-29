--
-- Name: extract_tagged_name(text, text); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.extract_tagged_name(_tag text, _text text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Examine the text provided and look for a substring that is preceded by the given tag,
**      and terminated by a space, semicolon, colon, comma, or forward slash
**      (or to the end of the text if not found)
**
**  Return values: substring, or '' if not found
**
**  Arguments:
**    _tag      The tag to look for, for example 'DTA:'
**    _text     The text to search
**
**  Auth:   grk
**  Date:   04/13/2009 grk - Initial release (Ticket #733, http://prismtrac.pnl.gov/trac/ticket/733)
**          07/29/2009 mem - Updated to return nothing if _tag is not found in _text
**                         - Added additional delimiters when searching for the end of the text to return after the tag
**          08/23/2012 mem - Expanded _tag from varchar(12) to varchar(64)
**          06/26/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved words
**
*****************************************************/
DECLARE
    _startPosition int;
    _result text;
    _matchPosition int;
BEGIN
    _startPosition := Position(_tag In _text);

    If Coalesce(_startPosition, 0) = 0 Then
        -- Match not found
        RETURN '';
    End If;

    -- Extract the text from the end of the tag to the next delimiter
    -- (or to the end of the line

    _startPosition := _startPosition + char_length(_tag);
    _result := Trim(Substring(_text, _startPosition, char_length(_text) ));

    -- Determine the position of the first space, semicolon, colon, comma, or forward slash
    SELECT Min(MatchPosition)
    INTO _matchPosition
    FROM (
        SELECT unnest(
               ARRAY[
                    Position(' '  In _result),
                    Position(';'  In _result),
                    Position(','  In _result),
                    Position(':'  In _result),
                    Position('/'  In _result)
               ]) As MatchPosition
         ) SearchQ
    WHERE MatchPosition > 0;

    If Coalesce(_matchPosition, 0) > 0 And char_length(_result) > 1 Then
        _result := Trim(Substring(_result, 1, _matchPosition - 1 ));
    End If;

    RETURN _result;
END
$$;


ALTER FUNCTION sw.extract_tagged_name(_tag text, _text text) OWNER TO d3l243;

--
-- Name: FUNCTION extract_tagged_name(_tag text, _text text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.extract_tagged_name(_tag text, _text text) IS 'ExtractTaggedName';

