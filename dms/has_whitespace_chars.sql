--
-- Name: has_whitespace_chars(text, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.has_whitespace_chars(_entityname text, _allowspace boolean DEFAULT false) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Check for whitespace characters: CRLF, tab, and space
**
**      Allows symbols and letters, including periods, dashes, and underscores
**
**      This function is called by numerous check constraints,
**      including on tables T_Dataset and T_Experiments
**
**  Arguments:
**    _entityName   Value to check
**    _allowSpace   When true, allow spaces
**
**  Returns values:
**      False if no whitespace characters, true if whitespace characters are present
**
**  Auth:   mem
**  Date:   02/15/2011
**          04/05/2022 mem - Ported to PostgreSQL
**          02/24/2023 mem - Change _allowSpace argument to boolean
**          05/22/2023 mem - Capitalize reserved words
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
BEGIN

    If Position(chr(10) In _entityName) > 0 Or              -- CR
       Position(chr(13) In _entityName) > 0 Or              -- LF
       Position(chr(9)  In _entityName) > 0 Or              -- Tab
       Not _allowspace And Position(' ' In _entityName) > 0 -- Space
    Then
        Return true;
    Else
        Return false;
    End If;

END
$$;


ALTER FUNCTION public.has_whitespace_chars(_entityname text, _allowspace boolean) OWNER TO d3l243;

--
-- Name: FUNCTION has_whitespace_chars(_entityname text, _allowspace boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.has_whitespace_chars(_entityname text, _allowspace boolean) IS 'HasWhitespaceChars or udfWhitespaceChars';

