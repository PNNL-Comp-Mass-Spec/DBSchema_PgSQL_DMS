--
-- Name: get_myemsl_url_data_package_name(text); Type: FUNCTION; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE FUNCTION dpkg.get_myemsl_url_data_package_name(_datapackagename text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Generates the MyEMSL URL required for viewing items stored for a given data package
**      KeyName comes from https://my.emsl.pnl.gov/myemsl/api/1/elasticsearch/generic-finder.js
**
**  Auth:   mem
**  Date:   09/24/2013
**          06/12/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**          09/08/2023 mem - Include schema name when calling function verify_sp_authorized()
**
*****************************************************/
DECLARE
    _keyName text := 'extended_metadata.gov_pnnl_emsl_dms_datapackage.name.untouched';
    _url text;
BEGIN
    _url := public.get_myemsl_url_work(_keyName, _dataPackageName);

    RETURN _url;
END
$$;


ALTER FUNCTION dpkg.get_myemsl_url_data_package_name(_datapackagename text) OWNER TO d3l243;

--
-- Name: FUNCTION get_myemsl_url_data_package_name(_datapackagename text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON FUNCTION dpkg.get_myemsl_url_data_package_name(_datapackagename text) IS 'GetMyEMSLUrlDataPackageName';

