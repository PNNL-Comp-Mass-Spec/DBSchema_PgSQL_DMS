--
-- Name: has_whitespace_chars(text, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.has_whitespace_chars(_entityname text, _allowspace integer DEFAULT 0) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Checks for whitespace characters: CRLF, tab, and space
**      Allows symbols and letters, including periods, dashes,
**      and underscores
**
**      This function is called by numerous Check Constraints,
**      including on tables T_Dataset and T_Experiments
**
**  Returns values: false if no problems, true if whitespace characters are present
**
**  Auth:   mem
**  Date:   02/15/2011
**          04/05/2022 mem - Ported to PostgreSQL
**
****************************************************/
DECLARE
    _invalidChars int := 0;
BEGIN

    If Position(Chr(10) In _entityName) > 0 OR              -- CR
       Position(Chr(13) In _entityName) > 0 OR              -- LF
       Position(Chr(9) In _entityName) > 0 OR               -- Tab
       _allowSpace = 0 And Position(' ' In _entityName) > 0 -- Space
    Then
        Return True;
    Else
        Return False;
    End If;

END
$$;


ALTER FUNCTION public.has_whitespace_chars(_entityname text, _allowspace integer) OWNER TO d3l243;

--
-- Name: FUNCTION has_whitespace_chars(_entityname text, _allowspace integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.has_whitespace_chars(_entityname text, _allowspace integer) IS 'HasWhitespaceChars or udfWhitespaceChars';

