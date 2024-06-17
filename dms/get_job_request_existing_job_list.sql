--
-- Name: get_job_request_existing_job_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_job_request_existing_job_list(_requestid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build a comma-separated list of existing jobs for the given
**      analysis job request using t_analysis_job_request_existing_jobs
**
**  Arguments:
**    _requestID    Analysis job request ID
**
**  Returns:
**      Comma-separated list
**
**  Auth:   mem
**  Date:   12/06/2005
**          03/27/2009 mem - Increased maximum size of the list to varchar(3500)
**          07/30/2019 mem - Get jobs from T_Analysis_Job_Request_Existing_Jobs
**          06/21/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(job::text, ', ' ORDER BY job)
    INTO _result
    FROM t_analysis_job_request_existing_jobs
    WHERE request_id = _requestID;

    If Coalesce(_result, '') = '' Then
        _result := '(none)';
    End If;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_job_request_existing_job_list(_requestid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_job_request_existing_job_list(_requestid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_job_request_existing_job_list(_requestid integer) IS 'GetJobRequestExistingJobList';

