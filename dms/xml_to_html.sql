--
-- Name: xml_to_html(xml); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.xml_to_html(_xml xml) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Converts XML to HTML text, surrounded by <pre> and </pre>
**
**      Adds a linefeed before each XML tag and changes the
**      less than and greater than signs to &lt; and &gt;
**
**  Return value: the XML as text
**
**  Auth:   mem
**  Date:   06/10/2010 mem - Initial version
**          06/24/2022 mem - Ported to PostgreSQL
**          11/15/2022 mem - Use a newline character (\n) to separate lines
**
*****************************************************/
DECLARE
    _text text;
    _newline text;
BEGIN
    If _xml Is Null Then
        _text := '';
    Else
        _newline := chr(10);

        _text := Trim(REPLACE(_xml::text, '<', _newline || '<'));
        _text := '<pre>' ||
                 REPLACE(REPLACE(_text, '<', '&lt;'), '>', '&gt;') ||
                 _newline ||
                 '</pre>';
    End If;

    RETURN _text;
END
$$;


ALTER FUNCTION public.xml_to_html(_xml xml) OWNER TO d3l243;

--
-- Name: FUNCTION xml_to_html(_xml xml); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.xml_to_html(_xml xml) IS 'XmlToHTML';

