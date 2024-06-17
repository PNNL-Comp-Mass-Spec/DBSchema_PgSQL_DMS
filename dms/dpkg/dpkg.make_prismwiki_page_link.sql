--
-- Name: make_prismwiki_page_link(text); Type: FUNCTION; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE FUNCTION dpkg.make_prismwiki_page_link(_packagename text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Generate URL to PRISM Wiki page for data package
**
**  Arguments:
**    _packageName  Data package name
**
**  Auth:   grk
**          06/05/2009 grk - Initial release
**          06/10/2009 grk - Using package name for link
**          06/11/2009 mem - Remove space from before https://
**          06/26/2009 mem - Update link format to be _baseURL plus the data package name
**          09/21/2012 mem - Change from https:// to http://
**          06/25/2022 mem - Ported to PostgreSQL
**          05/30/2023 mem - Use format() for string concatenation
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          10/12/2023 mem - Change from http:// to https://
**
*****************************************************/
DECLARE
    _result text;
    _baseURL text;
    _temp text;
BEGIN
    _baseURL := 'https://prismwiki.pnl.gov/wiki/DataPackages:';

    _temp := Trim(Coalesce(_packageName, ''));

    -- Replace invalid path characters with an underscore
    _temp := Replace(_temp, ' ', '_');
    _temp := Replace(_temp, '/', '_');
    _temp := Replace(_temp, '\', '_');
    _temp := Replace(_temp, ':', '_');
    _temp := Replace(_temp, '*', '_');
    _temp := Replace(_temp, '?', '_');
    _temp := Replace(_temp, '"', '_');
    _temp := Replace(_temp, '>', '_');
    _temp := Replace(_temp, '<', '_');
    _temp := Replace(_temp, '|', '_');

    -- Replace other characters that we'd rather not see in the wiki link
    _temp := Replace(_temp, '''', '_');
    _temp := Replace(_temp, '||', '_');
    _temp := Replace(_temp, '-', '_');

    _result := format('%s%s', _baseURL, _temp);

    RETURN _result;
END
$$;


ALTER FUNCTION dpkg.make_prismwiki_page_link(_packagename text) OWNER TO d3l243;

--
-- Name: FUNCTION make_prismwiki_page_link(_packagename text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON FUNCTION dpkg.make_prismwiki_page_link(_packagename text) IS 'MakePRISMWikiPageLink';

