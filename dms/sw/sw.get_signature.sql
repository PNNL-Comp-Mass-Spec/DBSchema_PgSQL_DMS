--
-- Name: get_signature(text); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.get_signature(_settings text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**    Get signature ID for given input string
**
**    Input string is hashed to pattern, and stored in table T_Signatures
**    Signature is integer reference to pattern
**
**  Return values: signature (integer), otherwise, 0
**
**  Auth:   grk
**  Date:   08/22/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          03/22/2011 mem - Now populating String, Entered, and Last_Used in T_Signatures
**          10/14/2022 mem - Ported to PostgreSQL
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/11/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _pattern text;
    _reference int;
BEGIN
    _reference := 0;

    ---------------------------------------------------
    -- Convert string to SHA-1 hash (upper case hex string)
    ---------------------------------------------------

    _pattern := sw.get_sha1_hash(_settings);

    If char_length(_pattern) > 32 Then
        -- Only keep the first 32 characters
        _pattern := Substring(_pattern, 1, 32);
    End If;

    ---------------------------------------------------
    -- Is it already in the signatures table?
    ---------------------------------------------------

    SELECT reference
    INTO _reference
    FROM sw.t_signatures
    WHERE pattern = _pattern;

    If Not FOUND Then

        ---------------------------------------------------
        -- Pattern not found; add it
        ---------------------------------------------------

        INSERT INTO sw.t_signatures (
            pattern,
            string,
            entered,
            last_used
        )
        VALUES (_pattern, _settings, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        RETURNING reference
        INTO _reference;

    Else
        ---------------------------------------------------
        -- Update Last_Used and possibly update String
        ---------------------------------------------------

        If Exists (SELECT reference FROM sw.t_signatures WHERE reference = _reference AND string IS NULL) Then
            UPDATE sw.t_signatures
            SET Last_Used = CURRENT_TIMESTAMP,
                String = _settings
            WHERE Reference = _reference;
        Else
            UPDATE sw.t_signatures
            SET last_used = CURRENT_TIMESTAMP
            WHERE reference = _reference;
        End If;
    End If;

    RETURN _reference;
END
$$;


ALTER FUNCTION sw.get_signature(_settings text) OWNER TO d3l243;

--
-- Name: FUNCTION get_signature(_settings text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.get_signature(_settings text) IS 'GetSignature';

