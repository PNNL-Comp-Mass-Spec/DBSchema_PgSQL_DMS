--
-- Name: create_like_clause_from_separated_string(text, text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.create_like_clause_from_separated_string(_filterlist text, _fieldname text, _separator text DEFAULT ','::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Parses the text in _filterList, splitting on _separator,
**      and generating a valid SQL ILike or Similar To clause for field _fieldName
**
**  Arguments:
**    _filterList   Item name(s) to find in the given field (supports wildcards); separate multiple names using the given separator
**    _fieldName    Field name (aka column name)
**    _separator    Separator, typically a comma
**
**  Auth:   jds
**  Date:   12/16/2004
**          07/26/2005 mem - Now trimming white space from beginning and end of text extracted from _filterList
**                         - Increased size of return variable from 2048 to 4096 characters
**          06/17/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved words
**          05/30/2023 mem - Use format() for string concatenation
**          09/11/2023 mem - Adjust capitalization of keywords
**          02/13/2024 mem - Use "Similar To" instead of "ILike" for items with underscores (which are treated as wildcards) or square brackets
**                         - Use public.parse_delimited_list() to split
**
*****************************************************/
DECLARE
    _currentValue text;
    _result text;
    _useSimilarTo boolean;
BEGIN
    _result := '';

    FOR _currentValue IN
        SELECT DISTINCT Replace(Value, '_', '[_]')
        FROM public.parse_delimited_list(_filterList, _separator)
    LOOP
        _useSimilarTo := Position('_' In _currentValue) > 0 OR
                         Position('[' In _currentValue) > 0 OR
                         Position(']' In _currentValue) > 0;

        If _result <> '' Then
            _result := format('%s OR ', _result);
        End If;

        If _useSimilarTo Then
            _result := format('%s((%s Similar To ''%s''))', _result, _fieldName, _currentValue );
        Else
            _result := format('%s((%s ILike ''%s''))',       _result, _fieldName, _currentValue );
        End If;

    END LOOP;

    RETURN _result;
END
$$;


ALTER FUNCTION public.create_like_clause_from_separated_string(_filterlist text, _fieldname text, _separator text) OWNER TO d3l243;

--
-- Name: FUNCTION create_like_clause_from_separated_string(_filterlist text, _fieldname text, _separator text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.create_like_clause_from_separated_string(_filterlist text, _fieldname text, _separator text) IS 'CreateLikeClauseFromSeparatedString';

