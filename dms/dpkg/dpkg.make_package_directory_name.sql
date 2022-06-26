--
-- Name: make_package_directory_name(integer, text); Type: FUNCTION; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE FUNCTION dpkg.make_package_directory_name(_datapackageid integer, _packagename text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
*       Generates a package directory name given a data package ID and name
**
**  Auth:   grk
**  Date:   05/21/2009 grk
**          05/29/2009 mem - Now replacing invalid characters with underscores
**          11/08/2010 mem - Now using first 96 characters of _packageName instead of first 40 characters
**          04/10/2013 mem - Now replacing commas
**          06/25/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    _packageName := Coalesce(_packageName, '');

    -- Replace spaces with an underscore
    _result := _dataPackageID::text || '_' || REPLACE(SUBSTRING(_packageName, 1, 96), ' ', '_');

    -- Replace invalid path characters with an underscore
    _result := REPLACE(_result, '/', '_');
    _result := REPLACE(_result, '\', '_');
    _result := REPLACE(_result, ':', '_');
    _result := REPLACE(_result, '*', '_');
    _result := REPLACE(_result, '?', '_');
    _result := REPLACE(_result, '"', '_');
    _result := REPLACE(_result, '>', '_');
    _result := REPLACE(_result, '<', '_');
    _result := REPLACE(_result, '|', '_');

    -- Replace other characters that we'd rather not see in the folder name
    _result := REPLACE(_result, '''', '_');
    _result := REPLACE(_result, '||', '_');
    _result := REPLACE(_result, '-', '_');
    _result := REPLACE(_result, ',', '_');

    RETURN _result;
END
$$;


ALTER FUNCTION dpkg.make_package_directory_name(_datapackageid integer, _packagename text) OWNER TO d3l243;

