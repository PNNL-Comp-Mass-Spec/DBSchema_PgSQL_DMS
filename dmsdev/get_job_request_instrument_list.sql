--
-- Name: get_job_request_instrument_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_job_request_instrument_list(_requestid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build a comma-separated list of instruments for the datasets associated with the given analysis job request
**
**  Return value: comma-separated list
**
**  Auth:   grk
**  Date:   11/01/2005 grk - Initial version
**          07/30/2019 mem - Get Dataset IDs from T_Analysis_Job_Request_Datasets
**          06/21/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(LookupQ.instrument, ', ' ORDER BY LookupQ.instrument)
    INTO _result
    FROM ( SELECT DISTINCT InstName.instrument
           FROM t_analysis_job_request_datasets AJRD
                INNER JOIN t_dataset DS
                  ON AJRD.dataset_id = DS.dataset_id
                INNER JOIN t_instrument_name InstName
                  ON DS.instrument_id = InstName.instrument_id
           WHERE AJRD.request_id = _requestID
         ) LookupQ;

    If _result = '' Then
        _result := '(none)';
    End If;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_job_request_instrument_list(_requestid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_job_request_instrument_list(_requestid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_job_request_instrument_list(_requestid integer) IS 'GetJobRequestInstrList';

