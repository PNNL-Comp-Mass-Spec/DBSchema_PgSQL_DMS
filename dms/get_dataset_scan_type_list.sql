--
-- Name: get_dataset_scan_type_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_dataset_scan_type_list(_datasetid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build a delimited list of actual scan types for the specified dataset
**
**      Scan types are sorted using column sort_key from table t_dataset_scan_type_glossary
**
**      To find missing scan types, use either of the following queries:
**
**      SELECT CASE WHEN Coalesce(MissingScanTypes, '') = ''
**                  THEN 'Table t_dataset_scan_type_glossary is up-to-date'
**                  ELSE format('Need to add scan %s to t_dataset_scan_type_glossary: %s',
**                              CASE WHEN MissingScanTypes LIKE '%,%' THEN 'types' ELSE 'type' END,
**                              MissingScanTypes)
**             END AS Comment
**      FROM (SELECT string_agg(T.scan_type, ', ' ORDER BY T.scan_type) AS MissingScanTypes
**            FROM (SELECT DISTINCT scan_type FROM t_dataset_scan_types) T
**                 LEFT OUTER JOIN t_dataset_scan_type_glossary G
**                   ON T.scan_type = G.scan_type
**            WHERE G.scan_type Is Null) LookupQ;
**
**      SELECT T.scan_type
**      FROM (SELECT DISTINCT scan_type
**            FROM t_dataset_scan_types) T
**                 LEFT OUTER JOIN t_dataset_scan_type_glossary G
**                   ON T.scan_type = G.scan_type
**      WHERE G.scan_type Is Null
**      ORDER BY T.scan_type;
**
**  Return value: comma-separated list
**
**  Auth:   mem
**  Date:   05/13/2010
**          06/13/2022 mem - Convert from a table-valued function to a scalar-valued function
**                         - Ported to PostgreSQL
**          12/06/2023 mem - Also sort by scan_type, in case the scan type is not defined in t_dataset_scan_type_glossary
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(LookupQ.scan_type, ', ' ORDER BY G.sort_key, LookupQ.scan_type)
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

