--
-- Name: get_taxid_synonym_list(integer); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.get_taxid_synonym_list(_taxonomyid integer) RETURNS public.citext
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Builds a delimited list of synonym names for the given Tax_ID value
**
**  Return value: comma-separated list
**
**  Auth:   mem
**  Date:   03/01/2016 mem - Initial version
**          03/30/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _list citext := null;
BEGIN
    SELECT string_agg(SourceQ.Synonym, ', ') INTO _list
    FROM (
        SELECT L.Synonym
        FROM ont.V_NCBI_Taxonomy_Alt_Name_List_Report L
        WHERE L.Tax_ID = _taxonomyID
        ORDER BY L.Synonym
        ) SourceQ;

    Return _list;
END
$$;


ALTER FUNCTION ont.get_taxid_synonym_list(_taxonomyid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_taxid_synonym_list(_taxonomyid integer); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.get_taxid_synonym_list(_taxonomyid integer) IS 'GetTaxIDSynonymList';

