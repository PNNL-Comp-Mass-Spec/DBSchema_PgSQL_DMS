--
-- Name: combine_paths(text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.combine_paths(_path1 text, _path2 text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/****************************************************
**  Appends a directory or file name to a path,
**  assuring that the two names are separated by a \
**
**  Auth:   mem
**  Date:   07/03/2006
**          04/15/2022 mem - Ported to PostgreSQL
**          05/30/2023 mem - Use format() for string concatenation
**          09/11/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _newPath text;
BEGIN

    _path1 := Trim(Coalesce(_path1, ''));
    _path2 := Trim(Coalesce(_path2, ''));

    If char_length(trim(_path1)) > 0 Then
        If char_length(trim(_path2)) = 0 Then
            _newPath := _path1;
        Else
            If Right(_path1, 1) <> '\' Then
                _path1 := format('%s\',_path1);
            End If;

            If Left(_path2, 1) = '\' Then
                _path2 := Substring(_path2, 2, char_length(_path2) - 1);
            End If;

            _newPath := format('%s%s', _path1, _path2);
        End If;
    Else
        _newPath := _path2;
    End If;

    RETURN _newPath;
END
$$;


ALTER FUNCTION public.combine_paths(_path1 text, _path2 text) OWNER TO d3l243;

--
-- Name: FUNCTION combine_paths(_path1 text, _path2 text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.combine_paths(_path1 text, _path2 text) IS 'CombinePaths';

