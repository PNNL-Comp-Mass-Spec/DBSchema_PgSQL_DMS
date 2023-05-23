--
-- Name: extract_server_name(text); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.extract_server_name(_path text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Extracts the server name from the given path
**
**  Auth:   mem
**  Date:   03/03/2010
**          06/26/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
****************************************************/
DECLARE
    _serverName text;
    _charPosition1 int;
    _charPosition2 int;
BEGIN
    _path := Trim(Coalesce(_path, ''));

    -- Initially set _serverName equal to _path
    _serverName := _path;

    If char_length(_path) > 0 Then
        -- Remove any '\' or '/' characters from the front of _path
        _path = Trim(Trim(_path, '\'), '/');

        -- Look for the next backslash or forward slash character
        _charPosition1 := position('\' in _path);
        _charPosition2 := position('/' in _path);

        If _charPosition1 = 0 And _charPosition2 = 0 Then
            _serverName := _path;
        ElseIf _charPosition1 > 1 And _charPosition1 < _charPosition2 Then
            _serverName := SubString(_path, 1, _charPosition1 - 1);
        ElseIf _charPosition2 > 1 Then
            _serverName := SubString(_path, 1, _charPosition2 - 1);
        End If;

    End If;

    RETURN _serverName;
END
$$;


ALTER FUNCTION sw.extract_server_name(_path text) OWNER TO d3l243;

--
-- Name: FUNCTION extract_server_name(_path text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.extract_server_name(_path text) IS 'ExtractServerName';

