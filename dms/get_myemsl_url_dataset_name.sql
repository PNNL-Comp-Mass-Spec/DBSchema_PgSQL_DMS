--
-- Name: get_myemsl_url_dataset_name(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_myemsl_url_dataset_name(_datasetname text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Generates the MyEMSL URL required for viewing items stored for a given dataset
**
**  Auth:   mem
**  Date:   09/12/2013
**          06/21/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**          09/08/2023 mem - Include schema name when calling function
**
*****************************************************/
DECLARE
    _keyName text := 'extended_metadata.gov_pnnl_emsl_dms_dataset.name.untouched';
BEGIN
    RETURN public.get_myemsl_url_work(_keyName, _datasetName);
END
$$;


ALTER FUNCTION public.get_myemsl_url_dataset_name(_datasetname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_myemsl_url_dataset_name(_datasetname text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_myemsl_url_dataset_name(_datasetname text) IS 'GetMyEMSLUrlDatasetName';

