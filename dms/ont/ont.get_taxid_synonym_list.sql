--
-- Name: get_taxid_synonym_list(integer); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.get_taxid_synonym_list(_taxonomyid integer) RETURNS public.citext
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**  	Builds a delimited list of synonym names for the given Tax_ID value
**
**  Return value: comma-separated list
**
**  Auth:   mem
**  Date:   03/01/2016 mem - Initial version
**          03/30/2022 mem - Ported to PostgreSQL
**          06/16/2022 mem - Move Order by clause into the string_agg function
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
DECLARE
    _list citext;
BEGIN
    SELECT string_agg(Synonym, ', ' ORDER BY Synonym)
    INTO _list
    FROM ont.V_NCBI_Taxonomy_Alt_Name_List_Report
    WHERE Tax_ID = _taxonomyID;

    RETURN _list;
END
$$;


ALTER FUNCTION ont.get_taxid_synonym_list(_taxonomyid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_taxid_synonym_list(_taxonomyid integer); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.get_taxid_synonym_list(_taxonomyid integer) IS 'GetTaxIDSynonymList';

