--
-- Name: parse_delimited_list_ordered(text, text, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.parse_delimited_list_ordered(_delimitedlist text, _delimiter text DEFAULT ','::text, _maxrows integer DEFAULT 0) RETURNS TABLE(entry_id integer, value text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Parse the text in _delimitedList and return a table containing the values
**
**      The table includes column entry_id to allow the calling procedure to sort the data
**      based on the data order in _delimitedList; The first row will have entry_id = 1
**
**      Note that if two commas in a row are encountered, the resultant table will contain an empty cell for that row
**
**      If _delimiter is chr(13) or chr(10), will split _delimitedList on CR or LF
**      In this case, blank lines will not be included in output table
**
**  Arguments:
**    _delimitedList     List of values, e.g. 'Value1,Value2'
**    _delimiter         Delimiter (comma by default)
**    _maxRows           Maximum number of rows to return (0 to return all); useful if parsing a comma-separated list of items and the final item is a comment field, which itself might contain commas
**
**  Auth:   mem
**  Date:   10/16/2007
**          03/27/2013 mem - Now replacing Tab characters, carriage returns and line feeds with _delimiter
**          01/14/2020 mem - Ported to PostgreSQL
**          06/10/2022 mem - Added parameter _maxRows
**
*****************************************************/
BEGIN

    -- Replace any CR or LF characters with _delimiter
    If _delimitedList Like '%' || chr(13) || '%' Then
        _delimitedList := Trim(Replace(_delimitedList, chr(13), _delimiter));
    End If;

    If _delimitedList Like '%' || chr(10) || '%' Then
        _delimitedList := Trim(Replace(_delimitedList, chr(10), _delimiter));
    End If;

    If _delimiter <> chr(9) Then
        -- Replace any tab characters with _delimiter
        If _delimitedList Like '%' || chr(9) || '%' Then
            _delimitedList := Trim(Replace(_delimitedList, chr(9), _delimiter));
        End If;
    End If;

    If Coalesce(_maxRows, 0) <= 0 Then
        _maxRows = 2147483647;
    End If;

    RETURN QUERY
    SELECT (Row_Number() OVER ())::int As entry_id, Trim(SplitQ.Value) AS ValueText
    FROM ( SELECT regexp_split_to_table(_delimitedList, _delimiter) AS Value
         ) SplitQ
    WHERE COALESCE(Trim(SplitQ.Value), '') <> ''
    LIMIT _maxRows;

END
$$;


ALTER FUNCTION public.parse_delimited_list_ordered(_delimitedlist text, _delimiter text, _maxrows integer) OWNER TO d3l243;

--
-- Name: FUNCTION parse_delimited_list_ordered(_delimitedlist text, _delimiter text, _maxrows integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.parse_delimited_list_ordered(_delimitedlist text, _delimiter text, _maxrows integer) IS 'ParseDelimitedListOrdered';

