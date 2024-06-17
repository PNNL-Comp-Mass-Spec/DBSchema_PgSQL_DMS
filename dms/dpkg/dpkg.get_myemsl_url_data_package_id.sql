--
-- Name: get_myemsl_url_data_package_id(integer); Type: FUNCTION; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE FUNCTION dpkg.get_myemsl_url_data_package_id(_datapackageid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Generate the MyEMSL URL required for viewing items stored for a given data package, by package ID
**      KeyName comes from https://my.emsl.pnl.gov/myemsl/api/1/elasticsearch/generic-finder.js
**
**  Arguments:
**    _dataPackageID    Data package ID
**
**  Auth:   mem
**  Date:   09/12/2013
**          06/12/2022 mem - Ported to PostgreSQL
**          06/26/2022 mem - Changed _dataPackageID argument from text to int
**          05/22/2023 mem - Capitalize reserved word
**          09/08/2023 mem - Include schema name when calling function verify_sp_authorized()
**
*****************************************************/
DECLARE
    _keyName text := 'extended_metadata.gov_pnnl_emsl_dms_datapackage.id';
    _url text;
BEGIN
    _url := public.get_myemsl_url_work(_keyName, _dataPackageID::text);

    RETURN _url;
END
$$;


ALTER FUNCTION dpkg.get_myemsl_url_data_package_id(_datapackageid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_myemsl_url_data_package_id(_datapackageid integer); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON FUNCTION dpkg.get_myemsl_url_data_package_id(_datapackageid integer) IS 'GetMyEMSLUrlDataPackageID';

