--
-- Name: extract_number_from_text(text, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.extract_number_from_text(_searchtext text, _startloc integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Examine the text provided to return the next integer value present, starting at _startLoc
**
**      See also function public.extract_integer
**      That function does not have a _startLoc parameter, and it returns null if a number is not found
**
**  Arguments:
**    _searchText   The text to search for a number
**    _startLoc     The position to start searching at
**
**  Returns:
**      Number found, or 0 if no number found
**
**  Auth:   mem
**  Date:   07/31/2007
**          04/26/2016 mem - Check for negative numbers
**          06/27/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _value int;
    _loc int;
    _textLength int;
    _nextChar char;
    _valueText text;
BEGIN
    _value := 0;

    _textLength := char_length(_searchText);

    If Coalesce(_startLoc, 0) > 1 Then
        _searchText := Substring(_searchText, _startLoc, _textLength);
        _textLength := char_length(_searchText);
    End If;

    -- Find the first integer in _searchText (starting at _startLoc if it was non-zero)
    _value := public.extract_integer(_searchText);

    RETURN _value;
END
$$;


ALTER FUNCTION public.extract_number_from_text(_searchtext text, _startloc integer) OWNER TO d3l243;

--
-- Name: FUNCTION extract_number_from_text(_searchtext text, _startloc integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.extract_number_from_text(_searchtext text, _startloc integer) IS 'ExtractNumberFromText';

