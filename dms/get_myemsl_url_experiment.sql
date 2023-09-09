--
-- Name: get_myemsl_url_experiment(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_myemsl_url_experiment(_experimentname text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Generates the MyEMSL URL required for viewing items stored for a given experiment
**
**  Auth:   mem
**  Date:   09/12/2013
**          06/21/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**          09/08/2023 mem - Include schema name when calling function
**
*****************************************************/
DECLARE
    _keyName text := 'extended_metadata.gov_pnnl_emsl_dms_experiment.name.untouched';
BEGIN
    RETURN public.get_myemsl_url_work(_keyName, _experimentName);
END
$$;


ALTER FUNCTION public.get_myemsl_url_experiment(_experimentname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_myemsl_url_experiment(_experimentname text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_myemsl_url_experiment(_experimentname text) IS 'GetMyEMSLUrlExperiment';

