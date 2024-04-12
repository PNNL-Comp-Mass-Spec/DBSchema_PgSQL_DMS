--
-- Name: get_sha1_hash(text, boolean); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.get_sha1_hash(_input text, _capitalize boolean DEFAULT true) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**    Compute the SHA-1 hash of the input string, returning the hash as a hexadecimal string
**
**  Arguments:
**    _input        Text to hash
**    _capitalize   If true, capitalize letters in the hash, otherwise leave as lowercase
**
**  Example results:
**    Select sw.get_sha1_hash('test', false);   -- a94a8fe5ccb19ba61c4c0873d391e987982fbbd3
**    Select sw.get_sha1_hash('test', true);    -- A94A8FE5CCB19BA61C4C0873D391E987982FBBD3
**    Select sw.get_sha1_hash('');              -- DA39A3EE5E6B4B0D3255BFEF95601890AFD80709
**    Select sw.get_sha1_hash(null);            -- null
**
**  Auth:   mem
**  Date:   06/26/2022 mem - Initial version
**          05/22/2023 mem - Capitalize reserved words
**
*****************************************************/
DECLARE
    _hexString text;
BEGIN
    _hexString := encode(digest(_input, 'sha1'), 'hex');

    If _capitalize Then
        RETURN Upper(_hexString);
    Else
        RETURN _hexString;
    End If;
END
$$;


ALTER FUNCTION sw.get_sha1_hash(_input text, _capitalize boolean) OWNER TO d3l243;

--
-- Name: FUNCTION get_sha1_hash(_input text, _capitalize boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.get_sha1_hash(_input text, _capitalize boolean) IS 'Replaces bin2hex(HashBytes(''SHA1'', ''text_to_hash'') on SQL Server)';

