--
-- Name: encode_base64(text); Type: FUNCTION; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE FUNCTION dpkg.encode_base64(_texttoencode text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Encodes the given text using base-64 encoding
**
**      From https://stackoverflow.com/a/23699204/1179467
**
**  Auth:   mem
**  Date:   09/12/2013
**          06/12/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _encodedText text;
BEGIN

    _encodedText := encode(_textToEncode::bytea, 'base64');

    return _encodedText;
END
$$;


ALTER FUNCTION dpkg.encode_base64(_texttoencode text) OWNER TO d3l243;

--
-- Name: FUNCTION encode_base64(_texttoencode text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON FUNCTION dpkg.encode_base64(_texttoencode text) IS 'EncodeBase64';

