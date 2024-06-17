--
-- Name: extract_integer(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.extract_integer(_in text) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
/****************************************************
**
**  Desc:
**  	Returns the first contiguous integer in parameter _in
**
**      Intended for use with EUS proposals that are typically numbers, but sometimes have letter suffixes
**
**  Arguments:
**    _in   Text to parse
**
**  Returns:
**      Extracted integer, or null if no integer was found
**
**  Auth:   mem
**  Date:   04/26/2016 mem - Initial release
**          04/15/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**          09/11/2023 mem - Use schema name with try_cast
**
*****************************************************/
DECLARE
    _value int;
BEGIN
    -- Option 1: use function try_cast to try to convert _in to an integer
    -- However, function try_cast relies on exception handling, so it's better to just use a RegEx match
    /*
    SELECT _out
    FROM public.try_cast(_in, NULL::int)
    INTO _value;

    If _value Is Null And Not _in Is Null Then
        -- _in is not an integer
        -- Look for the longest integer in _in, allowing for negative numbers

        _value := (regexp_match(_in, '-?[0-9]+'))[1];
    End If;
    */

    -- Function regexp_match returns an array, or null if no MATCH
    -- Use [1] to select the first item in the array
    RETURN (regexp_match(_in, '-?[0-9]+'))[1];
END
$$;


ALTER FUNCTION public.extract_integer(_in text) OWNER TO d3l243;

--
-- Name: FUNCTION extract_integer(_in text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.extract_integer(_in text) IS 'ExtractInteger or ExtractNumberFromText';

