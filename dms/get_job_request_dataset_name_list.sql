--
-- Name: get_job_request_dataset_name_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_job_request_dataset_name_list(_requestid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds a comma separated list of the datasets
**      associated with the given analysis job request
**
**  Return value: comma separated list
**
**  Auth:   mem
**  Date:   07/30/2019 mem - Initial release
**          06/21/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(LookupQ.dataset, ', ' ORDER BY LookupQ.dataset)
    INTO _result
    FROM ( SELECT DISTINCT DS.dataset
           FROM t_analysis_job_request_datasets AJRD
                INNER JOIN t_dataset DS
                  ON AJRD.dataset_id = DS.dataset_id
           WHERE AJRD.request_id = _requestID
         ) LookupQ;

    If Coalesce(_result, '') = '' Then
        _result := '(none)';
    End If;

    Return _result;
END
$$;


ALTER FUNCTION public.get_job_request_dataset_name_list(_requestid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_job_request_dataset_name_list(_requestid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_job_request_dataset_name_list(_requestid integer) IS 'GetJobRequestDatasetNameList';

