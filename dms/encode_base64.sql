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
**
*****************************************************/
DECLARE
    _encodedText text;
BEGIN

    _encodedText := encode(_textToEncode::bytea, 'base64');

    RETURN _encodedText;
END
$$;


ALTER FUNCTION public.encode_base64(_texttoencode text) OWNER TO d3l243;

--
-- Name: FUNCTION encode_base64(_texttoencode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.encode_base64(_texttoencode text) IS 'EncodeBase64';

