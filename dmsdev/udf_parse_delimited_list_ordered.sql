--
-- Name: udf_parse_delimited_list_ordered(text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.udf_parse_delimited_list_ordered(_delimitedlist text, _delimiter text DEFAULT ','::text) RETURNS TABLE(entry_id integer, value text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Parses the text in _delimitedList and returns a table
**       containing the values.  The table includes column entry_id
**       to allow the calling procedure to sort the data based on the
**       data order in _delimitedList.  The first row will have entry_id = 1
**
**      Note that if two commas in a row are encountered,
**       the resultant table will contain an empty cell for that row
**
**      _delimitedList should be of the form 'Value1,Value2'
**
**  Auth:   mem
**  Date:   01/14/2020 mem - Initial version
**
****************************************************/
BEGIN

    -- Replace any CR or LF characters with _delimiter
    If _delimitedList Like '%' || Chr(13) || '%' Then
        _delimitedList := Trim(Replace(_delimitedList, Chr(13), _delimiter));
    End If;

    If _delimitedList Like '%' || Chr(10) || '%' Then
        _delimitedList := Trim(Replace(_delimitedList, Chr(10), _delimiter));
    End If;

    If _delimiter <> Chr(9) Then
        -- Replace any tab characters with _delimiter
        If _delimitedList Like '%' || Chr(9) || '%' Then
            _delimitedList := Trim(Replace(_delimitedList, Chr(9), _delimiter));
        End If;
    End If;

    RETURN QUERY
    SELECT (Row_Number() OVER ())::int As entry_id, Trim(SplitQ.Value) AS ValueText
    FROM ( SELECT regexp_split_to_table(_delimitedList, _delimiter) AS Value
         ) SplitQ
    WHERE COALESCE(Trim(SplitQ.Value), '') <> '';

END
$$;


ALTER FUNCTION public.udf_parse_delimited_list_ordered(_delimitedlist text, _delimiter text) OWNER TO d3l243;

