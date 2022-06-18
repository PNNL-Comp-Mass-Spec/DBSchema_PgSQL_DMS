--
-- Name: get_myemsl_url_data_package_id(text); Type: FUNCTION; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE FUNCTION dpkg.get_myemsl_url_data_package_id(_datapackageid text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Generates the MyEMSL URL required for viewing items stored for a given data package, by package ID
**      KeyName comes from https://my.emsl.pnl.gov/myemsl/api/1/elasticsearch/generic-finder.js
**
**  Auth:   mem
**  Date:   09/12/2013
**          06/12/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _keyName text := 'extended_metadata.gov_pnnl_emsl_dms_datapackage.id';
    _url text;
BEGIN
    _url := public.get_myemsl_url_work(_keyName, _dataPackageID);

    Return _url;
END
$$;


ALTER FUNCTION dpkg.get_myemsl_url_data_package_id(_datapackageid text) OWNER TO d3l243;

--
-- Name: FUNCTION get_myemsl_url_data_package_id(_datapackageid text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON FUNCTION dpkg.get_myemsl_url_data_package_id(_datapackageid text) IS 'GetMyEMSLUrlDataPackageID';

