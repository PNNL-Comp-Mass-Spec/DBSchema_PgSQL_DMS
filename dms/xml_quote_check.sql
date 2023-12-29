--
-- Name: xml_quote_check(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.xml_quote_check(_text text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Replace double quotes, less than signs, and greater than signs
**      with HTML entity codes to avoid malformed XML
**        " is changed to &quot;
**        < is changed to &lt;
**        > is changed to &gt;
**
**  Return value: the updated text
**
**  Auth:   mem
**  Date:   02/03/2011 mem - Initial version
**          02/25/2011 mem - Now replacing < and > with &lt; and &gt;
**          05/08/2013 mem - Now changing Null strings to ''
**          06/24/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
BEGIN
    _text := Coalesce(_text, '');
    _text := Replace(_text, '"', '&quot;');
    _text := Replace(_text, '<', '&lt;');
    _text := Replace(_text, '>', '&gt;');

    RETURN _text;
END
$$;


ALTER FUNCTION public.xml_quote_check(_text text) OWNER TO d3l243;

--
-- Name: FUNCTION xml_quote_check(_text text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.xml_quote_check(_text text) IS 'XMLQuoteCheck';

