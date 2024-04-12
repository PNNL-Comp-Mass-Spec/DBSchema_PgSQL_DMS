--
-- Name: v_ncbi_taxonomy_cached; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_ncbi_taxonomy_cached AS
 SELECT tax_id,
    name,
    rank,
    parent_tax_id,
    synonyms,
    synonym_list
   FROM ont.t_ncbi_taxonomy_cached;


ALTER VIEW ont.v_ncbi_taxonomy_cached OWNER TO d3l243;

--
-- Name: TABLE v_ncbi_taxonomy_cached; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_ncbi_taxonomy_cached TO readaccess;
GRANT SELECT ON TABLE ont.v_ncbi_taxonomy_cached TO writeaccess;

