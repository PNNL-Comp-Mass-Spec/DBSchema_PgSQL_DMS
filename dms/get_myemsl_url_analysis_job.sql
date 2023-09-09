--
-- Name: get_myemsl_url_analysis_job(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_myemsl_url_analysis_job(_jobresultsfoldername text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Generates the MyEMSL URL required for viewing items stored for a given analysis job
**
**  Arguments:
**    _jobResultsFolderName   For example, SIC201309120240_Auto978018
**
**  Auth:   mem
**  Date:   09/12/2013
**          06/21/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**          09/08/2023 mem - Include schema name when calling function
**
*****************************************************/
DECLARE
    _keyName text := 'extended_metadata.gov_pnnl_emsl_dms_analysisjob.name.untouched';
BEGIN
    RETURN public.get_myemsl_url_work(_keyName, _jobResultsFolderName);
END
$$;


ALTER FUNCTION public.get_myemsl_url_analysis_job(_jobresultsfoldername text) OWNER TO d3l243;

--
-- Name: FUNCTION get_myemsl_url_analysis_job(_jobresultsfoldername text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_myemsl_url_analysis_job(_jobresultsfoldername text) IS 'GetMyEMSLUrlAnalysisJob';

