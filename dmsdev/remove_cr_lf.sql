--
-- Name: remove_cr_lf(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.remove_cr_lf(_text text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Remove carriage returns and line feeds from the text, replacing them with semicolons
**      After removing, also trim leading or trailing commas and semicolons
**
**  Return value: Updated string
**
**  Arguments:
**    _text   Text to search
**
**  Auth:   mem
**  Date:   02/25/2021 mem - Initial version
**          06/23/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**          09/11/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
BEGIN
    _text := Replace(_text, chr(13) || chr(10), '; ');
    _text := Replace(_text, chr(10), '; ');
    _text := Replace(_text, chr(13), '; ');

    -- Check for leading or trailing whitespace, comma, or semicolon
    _text := Trim(_text);
    _text := Trim(_text, ',');
    _text := Trim(_text, ';');

    RETURN _text;
END
$$;


ALTER FUNCTION public.remove_cr_lf(_text text) OWNER TO d3l243;

--
-- Name: FUNCTION remove_cr_lf(_text text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.remove_cr_lf(_text text) IS 'RemoveCrLf';

