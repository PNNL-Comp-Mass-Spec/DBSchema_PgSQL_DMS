--
-- Name: udf_parse_delimited_list(text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.udf_parse_delimited_list(_delimitedlist text, _delimiter text DEFAULT ','::text) RETURNS TABLE(value text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Parses the text in _delimitedList and returns a table containing the values
**
**      _delimitedList should be of the form 'Value1,Value2'
**      Will not return empty string values, e.g.
**       if the list is 'Value1,,Value2' or ',Value1,Value2'
**       the table will only contain entries 'Value1' and 'Value2'
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
    SELECT Trim(SplitQ.Value) ValueText
    FROM (  SELECT regexp_split_to_table(_delimitedList, _delimiter) AS Value
         ) SplitQ
    WHERE COALESCE(Trim(SplitQ.Value), '') <> '';

END
$$;


ALTER FUNCTION public.udf_parse_delimited_list(_delimitedlist text, _delimiter text) OWNER TO d3l243;

