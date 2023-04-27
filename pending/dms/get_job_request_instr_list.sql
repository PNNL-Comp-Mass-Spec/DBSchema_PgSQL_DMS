--
CREATE OR REPLACE FUNCTION public.get_job_request_instr_list
(
    _requestID int
)
RETURNS text
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Builds a comma separated list of instruments for the datasets
**      associated with the given analysis job request
**
**  Auth:   grk
**  Date:   11/01/2005 grk - Initial version
**          07/30/2019 mem - Get Dataset IDs from T_Analysis_Job_Request_Datasets
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _list text := '';
BEGIN

    SELECT
        _list = _list + CASE
                            WHEN _list = '' THEN Instrument
                            ELSE ', ' || Instrument
                        END
    FROM
    (
        SELECT DISTINCT InstName.instrument As Instrument
        FROM t_analysis_job_request_datasets AJRD
             INNER JOIN t_dataset DS
               ON AJRD.dataset_id = DS.dataset_id
             INNER JOIN t_instrument_name InstName
               ON DS.instrument_id = InstName.instrument_id
        WHERE AJRD.request_id = _requestID
    ) TX

    If _list = '' Then
        _list := '(none)';
    End If;

    RETURN _list;

END
$$;

COMMENT ON FUNCTION public.get_job_request_instr_list IS 'GetJobRequestInstrList';
