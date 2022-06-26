--
-- Name: get_xml_row(integer, text, text); Type: FUNCTION; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE FUNCTION dpkg.get_xml_row(_data_package_id integer, _type text, _itemid text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Returns a data row in XML format listing data package id, item type, and item ID
**
**  Auth:   grk
**  Date:   05/26/2010 grk
**          06/25/2022 mem - Ported to PostgreSQL
**
*****************************************************/

BEGIN
    RETURN '<item pkg="' || _data_Package_ID::text || '" type="' || _type || '" id="' || _itemID || '"/>';
END
$$;


ALTER FUNCTION dpkg.get_xml_row(_data_package_id integer, _type text, _itemid text) OWNER TO d3l243;

--
-- Name: FUNCTION get_xml_row(_data_package_id integer, _type text, _itemid text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON FUNCTION dpkg.get_xml_row(_data_package_id integer, _type text, _itemid text) IS 'GetXMLRow';

