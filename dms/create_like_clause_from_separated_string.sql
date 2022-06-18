--
-- Name: create_like_clause_from_separated_string(text, text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.create_like_clause_from_separated_string(_instring text, _fieldname text, _separator text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Parses the text in _inString, looking for _separator
**          and generating a valid SQL Like clause for field _fieldName
**
**  Auth:   jds
**  Date:   12/16/2004
**          07/26/2005 mem - Now trimming white space from beginning and end of text extracted from _inString
**                         - Increased size of return variable from 2048 to 4096 characters
**          06/17/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _sepPosition int;
    _result text;
    _i int;
BEGIN
    _inString := replace(_inString, '_', '[_]');
    _result := ' ';
    _i := 1;

    WHILE char_length(_inString) > 0 Loop
        _sepPosition := position(_separator in _inString);

        If _sepPosition > 0 Then
            if _i = 1 Then
                _result := '((' || _fieldName || ' ILike ''' || Trim(substring(_inString, 1, _sepPosition - 1)) || ''')';
            Else
                _result := _result || ' OR ' || '(' || _fieldName || ' ILike ''' || Trim(substring(_inString, 1, _sepPosition - 1)) || ''')';
            End If;

            _i := _i + 1;
            _inString := substring(_inString, _sepPosition + 1, char_length(_inString) - 1);

            continue;
        Else
            if _i = 1 Then
                _result := '((' || _fieldName || ' ILike ''' || Trim(_inString) || '''))';
            Else
                _result := _result || ' OR ' || '(' || _fieldName || ' ILike ''' || Trim(_inString) || '''))';
            End If;

            exit;
        End If;
    End Loop;

    _result := rtrim(_result);

    return _result;
END
$$;


ALTER FUNCTION public.create_like_clause_from_separated_string(_instring text, _fieldname text, _separator text) OWNER TO d3l243;

--
-- Name: FUNCTION create_like_clause_from_separated_string(_instring text, _fieldname text, _separator text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.create_like_clause_from_separated_string(_instring text, _fieldname text, _separator text) IS 'CreateLikeClauseFromSeparatedString';

