--
-- Name: make_prismwiki_page_link(text); Type: FUNCTION; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE FUNCTION dpkg.make_prismwiki_page_link(_packagename text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Generates URL to PRISM Wiki page for data package
**
**  Auth:   grk
**          06/05/2009 grk - initial release
**          06/10/2009 grk - using package name for link
**          06/11/2009 mem - Removed space from before https://
**          06/26/2009 mem - Updated link format to be _baseURL plus the data package name
**          09/21/2012 mem - Changed from https:// to http://
**          06/25/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
    _baseURL text;
    _temp text;
BEGIN
    _baseURL := 'http://prismwiki.pnl.gov/wiki/DataPackages:';

    _temp := Coalesce(_packageName, '');

    -- Replace invalid path characters with an underscore
    _temp := REPLACE(_temp, ' ', '_');
    _temp := REPLACE(_temp, '/', '_');
    _temp := REPLACE(_temp, '\', '_');
    _temp := REPLACE(_temp, ':', '_');
    _temp := REPLACE(_temp, '*', '_');
    _temp := REPLACE(_temp, '?', '_');
    _temp := REPLACE(_temp, '"', '_');
    _temp := REPLACE(_temp, '>', '_');
    _temp := REPLACE(_temp, '<', '_');
    _temp := REPLACE(_temp, '|', '_');

    -- Replace other characters that we'd rather not see in the wiki link
    _temp := REPLACE(_temp, '''', '_');
    _temp := REPLACE(_temp, '||', '_');
    _temp := REPLACE(_temp, '-', '_');

    _result := _baseURL || _temp;

    RETURN _result;
END
$$;


ALTER FUNCTION dpkg.make_prismwiki_page_link(_packagename text) OWNER TO d3l243;

--
-- Name: FUNCTION make_prismwiki_page_link(_packagename text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON FUNCTION dpkg.make_prismwiki_page_link(_packagename text) IS 'MakePRISMWikiPageLink';
