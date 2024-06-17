--
-- Name: get_data_package_dataset_list(integer); Type: FUNCTION; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE FUNCTION dpkg.get_data_package_dataset_list(_datapackageid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build delimited list of datasets for given data package
**
**  Arguments:
**    _dataPackageID    Data package ID
**
**  Returns:
**      Comma-separated list
**
**  Auth:   mem
**  Date:   10/22/2014 mem - Initial version
**          06/12/2022 mem - Ported to PostgreSQL
**          04/04/2023 mem - Use char_length() to determine string length
**          09/28/2023 mem - Obtain dataset names from t_dataset
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(DS.Dataset, ', ' ORDER BY DS.Dataset)
    INTO _result
    FROM dpkg.t_data_package_datasets DPD
         INNER JOIN public.t_dataset DS
           ON DPD.dataset_id = DS.dataset_id
    WHERE DPD.data_pkg_id = _dataPackageID AND
          char_length(Coalesce(DS.Dataset, '')) > 0;

    RETURN _result;
END
$$;


ALTER FUNCTION dpkg.get_data_package_dataset_list(_datapackageid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_data_package_dataset_list(_datapackageid integer); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON FUNCTION dpkg.get_data_package_dataset_list(_datapackageid integer) IS 'GetDataPackageDatasetList';

