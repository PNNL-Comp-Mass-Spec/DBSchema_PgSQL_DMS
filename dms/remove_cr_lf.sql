--
-- Name: remove_cr_lf(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.remove_cr_lf(_text text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Removes carriage returns and line feeds from the text
**      After removing, also trims leading or trailing commas and semicolons
**
**  Return value: Updated string
**
**  Arguments:
**    _text   Text to search
**
**  Auth:   mem
**  Date:   02/25/2021 mem - Initial version
**          06/23/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    _text := REPLACE(_text, CHR(13) || CHR(10), '; ');
    _text := REPLACE(_text, CHR(10), '; ');
    _text := REPLACE(_text, CHR(13), '; ');

    -- Check for leading or trailing whitespace, comma, or semicolon
    _text := Trim(_text);
    _text := Trim(_text, ',');
    _text := Trim(_text, ';');

    Return _text;
END
$$;


ALTER FUNCTION public.remove_cr_lf(_text text) OWNER TO d3l243;

--
-- Name: FUNCTION remove_cr_lf(_text text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.remove_cr_lf(_text text) IS 'RemoveCrLf';

