--
-- Name: encode_base64(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.encode_base64(_texttoencode text) RETURNS text
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
**          05/22/2023 mem - Capitalize reserved word
**          05/30/2023 mem - Remove line feeds from the encoded text
**
*****************************************************/
DECLARE
    _encodedText text;
BEGIN
    -- Although Replace() could be used to remove the line feeds, translate() is better since it steps through the string one byte at a time
    -- _encodedText :=Replace(encode(_textToEncode::bytea, 'base64'), chr(10), '');

    _encodedText := translate(encode(_textToEncode::bytea, 'base64'), E'\n', '');

    RETURN _encodedText;
END
$$;


ALTER FUNCTION public.encode_base64(_texttoencode text) OWNER TO d3l243;

--
-- Name: FUNCTION encode_base64(_texttoencode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.encode_base64(_texttoencode text) IS 'EncodeBase64';

