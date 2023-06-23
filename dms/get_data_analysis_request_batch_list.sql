--
-- Name: get_data_analysis_request_batch_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_data_analysis_request_batch_list(_dataanalysisrequestid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds delimited list of batch IDs
**      associated with the given data analysis request
**
**  Return value: comma-separated list
**
**  Auth:   mem
**  Date:   03/25/2022 mem - Initial version
**          06/10/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text := '';
BEGIN
    SELECT string_agg(batch_id::text, ', ' ORDER BY batch_id)
    INTO _result
    FROM t_data_analysis_request_batch_ids
    WHERE request_id = _dataAnalysisRequestID;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_data_analysis_request_batch_list(_dataanalysisrequestid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_data_analysis_request_batch_list(_dataanalysisrequestid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_data_analysis_request_batch_list(_dataanalysisrequestid integer) IS 'GetDataAnalysisRequestBatchList';

