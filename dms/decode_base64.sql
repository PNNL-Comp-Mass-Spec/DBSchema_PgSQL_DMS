--
-- Name: decode_base64(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.decode_base64(_encodedtext text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Decode the given text using base-64 encoding
**
**      From https://stackoverflow.com/a/69247729/1179467
**
**  Arguments:
**    _encodedText      Base-64 encoded text to decode
**
**  Auth:   mem
**  Date:   09/12/2013
**          06/17/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
DECLARE
    _decodedText bytea;
BEGIN

    _decodedText := decode(_encodedText, 'base64');

    RETURN convert_from(_decodedText, 'UTF8');
END
$$;


ALTER FUNCTION public.decode_base64(_encodedtext text) OWNER TO d3l243;

--
-- Name: FUNCTION decode_base64(_encodedtext text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.decode_base64(_encodedtext text) IS 'DecodeBase64';

