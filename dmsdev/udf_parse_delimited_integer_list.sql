--
-- Name: udf_parse_delimited_integer_list(text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.udf_parse_delimited_integer_list(_delimitedlist text, _delimiter text DEFAULT ','::text) RETURNS TABLE(value integer)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Parses the text in _delimitedList and returns a table containing the values (as integers)
**
**      _delimitedList should be of the form 'Value1,Value2'
**      Ignores empty strings and any items that are not integers, e.g.
**       if the list is '1,,2,test,3,4.2,5'
**       the table will contain four numbers: 1, 2, 3, 5
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
    SELECT FilterQ.ValueText::int
    FROM (  SELECT Trim(SplitQ.Value) ValueText
            FROM (  SELECT regexp_split_to_table(_delimitedList, _delimiter) AS Value
            ) SplitQ
            WHERE COALESCE(Trim(SplitQ.Value), '') ~ '^\d+$'
        ) FilterQ;

END
$_$;


ALTER FUNCTION public.udf_parse_delimited_integer_list(_delimitedlist text, _delimiter text) OWNER TO d3l243;

