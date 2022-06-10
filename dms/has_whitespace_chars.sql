--
-- Name: has_whitespace_chars(text, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.has_whitespace_chars(_entityname text, _allowspace integer DEFAULT 0) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
/****************************************************
**  Checks for whitespace characters: CRLF, tab, and space
**  Allows symbols and letters, including periods, dashes,
**  and underscores
**
**  Returns false if no problems
**  Returns true if whitespace characters are present
**
**  This function is called by numerous Check Constraints,
**  including on tables T_Dataset and T_Experiments
**
**  Auth:   mem
**  Date:   02/15/2011
**          04/05/2022 mem - Ported to PostgreSQL
**
****************************************************/
DECLARE
    _invalidChars int := 0;
BEGIN

    If position(Chr(10) in _entityName) > 0 OR              -- CR
       position(Chr(13) in _entityName) > 0 OR              -- LF
       position(Chr(9) in _entityName) > 0 OR               -- Tab
       _allowSpace = 0 AND position(' ' in _entityName) > 0 -- Space
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

COMMENT ON FUNCTION public.has_whitespace_chars(_entityname text, _allowspace integer) IS 'HasWhitespaceChars';

