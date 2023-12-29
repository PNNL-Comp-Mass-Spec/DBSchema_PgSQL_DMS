--
-- Name: get_myemsl_url_work(text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_myemsl_url_work(_keyname text, _value text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Generate the MyEMSL URL required for viewing items in MyEMSL
**
**  Auth:   mem
**  Date:   09/12/2013
**          06/12/2022 mem - Ported to PostgreSQL
**          05/30/2023 mem - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _json text;
    _encodedText text;
BEGIN
    -- Valid key names are defined in https://my.emsl.pnl.gov/myemsl/api/1/elasticsearch/generic-finder.js
    -- They include:
    --   extended_metadata.gov_pnnl_emsl_dms_analysisjob.name.untouched
    --   extended_metadata.gov_pnnl_emsl_dms_analysisjob.tool.name.untouched
    --   extended_metadata.gov_pnnl_emsl_dms_campaign.name.untouched
    --   extended_metadata.gov_pnnl_emsl_dms_datapackage.name.untouched
    --   extended_metadata.gov_pnnl_emsl_dms_dataset.name.untouched
    --   extended_metadata.gov_pnnl_emsl_dms_experiment.name.untouched
    --   extended_metadata.gov_pnnl_emsl_instrument.name.untouched
    --   ext  (filename extension)

    _json := format('{ "pacifica-search-simple": { "v": 1, "facets_set": [{"key": "%s", "value":"%s"}] } }', _keyName, _value);

    _encodedText = public.encode_base64(_json);

    RETURN format('https://my.emsl.pnl.gov/myemsl/search/simple/%s', _encodedText);
END
$$;


ALTER FUNCTION public.get_myemsl_url_work(_keyname text, _value text) OWNER TO d3l243;

--
-- Name: FUNCTION get_myemsl_url_work(_keyname text, _value text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_myemsl_url_work(_keyname text, _value text) IS 'GetMyEMSLUrlWork';

