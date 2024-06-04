--
-- Name: parse_delimited_list(text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.parse_delimited_list(_delimitedlist text, _delimiter text DEFAULT ','::text) RETURNS TABLE(value text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Parse the text in _delimitedList and return a table containing the values
**
**      _delimitedList should be of the form 'Value1,Value2'
**
**      Will not return empty string values, e.g.
**      if the list is 'Value1,,Value2' or ',Value1,Value2'
**      the table will only contain entries 'Value1' and 'Value2'
**
**      If _delimiter is chr(13) or chr(10), will split _delimitedList on CR or LF
**      In this case, blank lines will not be included in the output table
**
**  Auth:   mem
**  Date:   06/06/2006
**          11/10/2006 mem - Updated to prevent blank values from being returned in the table
**          03/14/2007 mem - Changed _delimitedList parameter from varchar(8000) to varchar(max)
**          04/02/2012 mem - Now removing Tab characters
**          03/27/2013 mem - Now replacing Tab characters, carriage returns and line feeds with _delimiter
**          01/14/2020 mem - Ported to PostgreSQL
**          02/23/2024 mem - Add special handling if _delimeter is CR, LF, or CRLF
**                         - Add support for _delimiter being '|' or '||'
**
*****************************************************/
DECLARE
    _delimiterIsCRorLF boolean := false;
BEGIN
    _delimitedList = Coalesce(_delimitedList, '');

    If Position(chr(13) In _delimiter) > 0 Or
       Position(chr(10) In _delimiter) > 0
    Then
        -- Change all carriage returns to linefeeds, and make the delimiter a linefeed
        _delimiterIsCRorLF := true;

        _delimiter := chr(10);
        _delimitedList := Trim(Replace(_delimitedList, chr(13), _delimiter));

    ElsIf Position('|'  In _delimiter) > 0 And
          Position('\|' In _delimiter) = 0
    Then
        -- Escape any vertical bars
        _delimiter := Trim(Replace(_delimiter, '|', '\|'));

    End If;

    If _delimitedList <> '' And Not _delimiterIsCRorLF Then
        -- Replace any CR or LF characters with _delimiter
        If Position(chr(13) In _delimiter) > 0 Then
            _delimitedList := Trim(Replace(_delimitedList, chr(13), _delimiter));
        End If;

        If Position(chr(10) In _delimiter) > 0 Then
            _delimitedList := Trim(Replace(_delimitedList, chr(10), _delimiter));
        End If;

        -- If _delimiter is a comma or a semicolon, replace any tab characters with _delimiter
        If Trim(_delimiter) In (',', ';') And Position(chr(9) In _delimitedList) > 0 Then
            _delimitedList := Trim(Replace(_delimitedList, chr(9), _delimiter));
        End If;
    End If;

    RETURN QUERY
    SELECT Trim(SplitQ.Value) ValueText
    FROM (SELECT regexp_split_to_table(_delimitedList, _delimiter) AS Value
         ) SplitQ
    WHERE COALESCE(Trim(SplitQ.Value), '') <> '';
END
$$;


ALTER FUNCTION public.parse_delimited_list(_delimitedlist text, _delimiter text) OWNER TO d3l243;

--
-- Name: FUNCTION parse_delimited_list(_delimitedlist text, _delimiter text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.parse_delimited_list(_delimitedlist text, _delimiter text) IS 'ParseDelimitedList';

