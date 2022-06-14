--
-- Name: get_dataset_scan_type_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_dataset_scan_type_list(_datasetid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds a delimited list of actual scan types
**      for the specified dataset
**
**  Return value: comma separated list
**
**  Auth:   mem
**  Date:   05/13/2010
**          06/13/2022 mem - Convert from a table-valued function to a scalar-valued function
**          06/13/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(LookupQ.scan_type, ', ' ORDER BY G.sort_key)
    INTO _result
    FROM ( SELECT DISTINCT scan_type
           FROM t_dataset_scan_types
           WHERE dataset_id = _datasetID) LookupQ
         LEFT OUTER JOIN t_dataset_scan_type_glossary G
           ON LookupQ.scan_type = G.scan_type;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_dataset_scan_type_list(_datasetid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_dataset_scan_type_list(_datasetid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_dataset_scan_type_list(_datasetid integer) IS 'GetDatasetScanTypeList';

