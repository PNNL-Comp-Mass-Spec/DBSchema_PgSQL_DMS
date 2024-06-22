--
-- Name: parse_delimited_integer_list(text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.parse_delimited_integer_list(_delimitedlist text, _delimiter text DEFAULT ','::text) RETURNS TABLE(value integer)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Parse the text in _delimitedList and return a table containing the values (as integers)
**
**      Ignores empty strings and any items that are not integers
**
**      For example, if the list is '1,,2,test,3,4.2,5',
**      the returned table will contain four numbers: 1, 2, 3, 5
**
**  Arguments:
**    _delimitedList    Delimited list of values, e.g. 'Value1,Value2'
**    _delimiter        Delimiter to use (defaults to a comma)
**
**  Auth:   mem
**  Date:   11/30/2006
**          03/14/2007 mem - Changed _delimitedList parameter from varchar(8000) to varchar(max)
**          04/02/2012 mem - Now removing Tab characters
**          03/27/2013 mem - Now replacing carriage return and line feed characters with _delimiter
**          01/14/2020 mem - Ported to PostgreSQL
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

    RETURN QUERY
    SELECT FilterQ.ValueText::int
    FROM (SELECT Trim(SplitQ.Value) ValueText
          FROM (SELECT regexp_split_to_table(_delimitedList, _delimiter) AS Value
               ) SplitQ
          WHERE COALESCE(Trim(SplitQ.Value), '') ~ '^\d+$'
         ) FilterQ;

END
$_$;


ALTER FUNCTION public.parse_delimited_integer_list(_delimitedlist text, _delimiter text) OWNER TO d3l243;

--
-- Name: FUNCTION parse_delimited_integer_list(_delimitedlist text, _delimiter text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.parse_delimited_integer_list(_delimitedlist text, _delimiter text) IS 'ParseDelimitedIntegerList';

