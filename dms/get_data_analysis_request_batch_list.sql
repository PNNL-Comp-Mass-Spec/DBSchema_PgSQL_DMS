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
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   mem
**  Date:   03/25/2022 mem - Initial version
**          06/10/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(cast(Batch_ID as text), ', ' ORDER BY Batch_ID)
    INTO _result
    FROM T_Data_Analysis_Request_Batch_IDs
    WHERE Request_ID = _dataAnalysisRequestID;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_data_analysis_request_batch_list(_dataanalysisrequestid integer) OWNER TO d3l243;

