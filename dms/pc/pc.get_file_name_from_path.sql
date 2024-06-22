--
-- Name: get_file_name_from_path(text, text); Type: FUNCTION; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION pc.get_file_name_from_path(_filepath text, _directoryseparator text DEFAULT '\'::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Look for the final backslash (or forward slash) in _filePath, then return the filename after the slash
**
**      If no slash in _filePath, or if no text after the directory separator, return an empty string
**
**  Arguments:
**    _filePath             File path, e.g. C:\Temp\Data.txt
**    _directorySeparator   Directory separator (defaults to a backslash)
**
**  Auth:   mem
**  Date:   10/09/2006
**          06/27/2022 mem - Ported to PostgreSQL
**          06/21/2024 mem - Add parameter _directorySeparator
**
*****************************************************/
DECLARE
    _slashLoc int;
    _pathLength int;
    _fileName text;
BEGIN
    _fileName := '';

    _filePath           := Trim(Coalesce(_filePath, ''));
    _directorySeparator := Trim(Coalesce(_directorySeparator, '\'));

    If Not _directorySeparator IN ('\', '/') Then
        RAISE WARNING 'Invalid directory separator "%"; will instead use "\"', _directorySeparator;
        _directorySeparator := '\';
    End If;

    _pathLength := char_length(_filePath);

    If _pathLength > 0 Then
        _slashLoc := Position(_directorySeparator In reverse(_filePath));
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


ALTER FUNCTION pc.get_file_name_from_path(_filepath text, _directoryseparator text) OWNER TO d3l243;

--
-- Name: FUNCTION get_file_name_from_path(_filepath text, _directoryseparator text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON FUNCTION pc.get_file_name_from_path(_filepath text, _directoryseparator text) IS 'GetFileNameFromPath';

