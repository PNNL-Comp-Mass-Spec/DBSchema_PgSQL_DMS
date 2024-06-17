--
-- Name: xml_to_html(xml); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.xml_to_html(_xml xml) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Convert XML to HTML text, surrounded by <pre> and </pre>
**
**      Add a line feed before each XML tag and changes the
**      less than signs and greater than signs to &lt; and &gt;
**
**  Returns:
**      The XML, as HTML formatted text
**
**  Auth:   mem
**  Date:   06/10/2010 mem - Initial version
**          06/24/2022 mem - Ported to PostgreSQL
**          11/15/2022 mem - Use a newline character (\n) to separate lines
**          05/31/2023 mem - Use format() for string concatenation
**          09/11/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _text text;
    _newline text;
BEGIN
    If _xml Is Null Then
        RETURN '';
    End If;

    _newline := chr(10);

    _text := Trim(Replace(_xml::text, '<', format('%s<', _newline)));

    _text := format('<pre>%s%s</pre>',
                    Replace(Replace(_text, '<', '&lt;'), '>', '&gt;'),
                    _newline);

    RETURN _text;
END
$$;


ALTER FUNCTION public.xml_to_html(_xml xml) OWNER TO d3l243;

--
-- Name: FUNCTION xml_to_html(_xml xml); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.xml_to_html(_xml xml) IS 'XmlToHTML';

