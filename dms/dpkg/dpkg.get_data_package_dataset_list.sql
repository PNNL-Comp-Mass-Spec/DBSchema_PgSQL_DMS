--
-- Name: get_data_package_dataset_list(integer); Type: FUNCTION; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE FUNCTION dpkg.get_data_package_dataset_list(_datapackageid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds delimited list of datasets for given data package
**
**  Return value: comma separated delimited list
**
**  Auth:   mem
**  Date:   10/22/2014 mem - Initial version
**          06/12/2022 mem - Ported to PostgreSQL
**          04/04/2023 mem - Use char_length() to determine string length
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(dataset, ', ' ORDER BY dataset)
    INTO _result
    FROM dpkg.t_data_package_datasets
    WHERE data_pkg_id = _dataPackageID And
          char_length(Coalesce(dataset, '')) > 0;

    RETURN _result;
END
$$;


ALTER FUNCTION dpkg.get_data_package_dataset_list(_datapackageid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_data_package_dataset_list(_datapackageid integer); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON FUNCTION dpkg.get_data_package_dataset_list(_datapackageid integer) IS 'GetDataPackageDatasetList';

