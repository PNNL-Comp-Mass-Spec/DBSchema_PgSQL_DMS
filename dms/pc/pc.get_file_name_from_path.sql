--
-- Name: get_file_name_from_path(text); Type: FUNCTION; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION pc.get_file_name_from_path(_filepath text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Looks for the final \ in _filePath, then returns the filename after the slash
**      If no slash in _filePath, or if no text after the slash, returns an empty string
**
**  Auth:   mem
**  Date:   10/09/2006
**          06/27/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _slashLoc int;
    _pathLength int;
    _fileName text;
BEGIN
    _fileName := '';

    _filePath := Trim(Coalesce(_filePath, ''));

    _pathLength := char_length(_filePath);

    If _pathLength > 0 Then
        _slashLoc := Position('\' In reverse(_filePath));
        If _slashLoc > 0 Then
            _slashLoc := _pathLength - _slashLoc + 1;
            If _slashLoc < _pathLength Then
                _fileName := Substring(_filePath, _slashLoc + 1, _pathLength);
            End If;
        End If;
    End If;

    RETURN _fileName;
END
$$;


ALTER FUNCTION pc.get_file_name_from_path(_filepath text) OWNER TO d3l243;

--
-- Name: FUNCTION get_file_name_from_path(_filepath text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON FUNCTION pc.get_file_name_from_path(_filepath text) IS 'GetFileNameFromPath';

