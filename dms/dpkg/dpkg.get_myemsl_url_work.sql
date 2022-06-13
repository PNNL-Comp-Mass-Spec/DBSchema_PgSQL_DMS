--
-- Name: get_myemsl_url_work(text, text); Type: FUNCTION; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE FUNCTION dpkg.get_myemsl_url_work(_keyname text, _value text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Generates the MyEMSL URL required for viewing items in MyEMSL
**
**  Auth:   mem
**  Date:   09/12/2013
**          06/12/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _json text;
    _encodedText text;
    _url text;
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

    _json := '{ "pacifica-search-simple": { "v": 1, "facets_set": [{"key": "' || _keyName || '", "value":"' || _value || '"}] } }';

    _encodedText = dpkg.encode_base64(_json);

    _url := 'https://my.emsl.pnl.gov/myemsl/search/simple/' || _encodedText;

    return _url;
END
$$;


ALTER FUNCTION dpkg.get_myemsl_url_work(_keyname text, _value text) OWNER TO d3l243;

--
-- Name: FUNCTION get_myemsl_url_work(_keyname text, _value text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON FUNCTION dpkg.get_myemsl_url_work(_keyname text, _value text) IS 'GetMyEMSLUrlWork';

