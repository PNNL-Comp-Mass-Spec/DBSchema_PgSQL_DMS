--
-- Name: get_job_request_instr_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_job_request_instr_list(_requestid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build a comma-separated list of instruments for the datasets associated with the given analysis job request
**
**  Auth:   grk
**  Date:   11/01/2005 grk - Initial version
**          07/30/2019 mem - Get Dataset IDs from T_Analysis_Job_Request_Datasets
**          06/02/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _list text := '';
BEGIN

    SELECT string_agg(Instrument, ', ' ORDER BY Instrument)
    INTO _list
    FROM ( SELECT DISTINCT InstName.instrument As Instrument
           FROM t_analysis_job_request_datasets AJRD
                  INNER JOIN t_dataset DS
                    ON AJRD.dataset_id = DS.dataset_id
                  INNER JOIN t_instrument_name InstName
                    ON DS.instrument_id = InstName.instrument_id
           WHERE AJRD.request_id = _requestID) TX;

    If Coalesce(_list, '') = '' Then
        _list := '(none)';
    End If;

    RETURN _list;

END
$$;


ALTER FUNCTION public.get_job_request_instr_list(_requestid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_job_request_instr_list(_requestid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_job_request_instr_list(_requestid integer) IS 'GetJobRequestInstrList';

