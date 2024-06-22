--
-- Name: extract_server_name(text); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.extract_server_name(_path text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Extract the server name from the given path
**
**  Arguments:
**    _path     File path (supports both backslashes and forward slashes)
**
**  Example usage:
**      SELECT sw.extract_server_name('\\proto-8\DMS3_Xfer\QC_Mam_23_01_b_20Apr23_Smeagol_WBEH-23-03-20\');
**      SELECT sw.extract_server_name('//proto-8/DMS3_Xfer/QC_Mam_23_01_b_20Apr23_Smeagol_WBEH-23-03-20/');
**
**  Auth:   mem
**  Date:   03/03/2010
**          06/26/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**          05/30/2023 mem - Use ElsIf for Else If
**          07/25/2023 mem - Fix logic bug for server paths
**          09/11/2023 mem - Adjust capitalization of keywords
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**
*****************************************************/
DECLARE
    _serverName text;
    _charPosition1 int;
    _charPosition2 int;
BEGIN
    _path := Trim(Coalesce(_path, ''));

    -- Initially set _serverName equal to _path
    _serverName := _path;

    If _path <> '' Then
        -- Remove any '\' or '/' characters from the front of _path
        _path := Trim(Trim(_path, '\'), '/');

        -- Look for the next backslash or forward slash character
        _charPosition1 := Position('\' In _path);
        _charPosition2 := Position('/' In _path);

        If _charPosition1 = 0 And _charPosition2 = 0 Then
            _serverName := _path;
        ElsIf _charPosition1 > 1 And (_charPosition2 = 0 OR _charPosition1 < _charPosition2) Then
            _serverName := Substring(_path, 1, _charPosition1 - 1);
        ElsIf _charPosition2 > 1 Then
            _serverName := Substring(_path, 1, _charPosition2 - 1);
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

