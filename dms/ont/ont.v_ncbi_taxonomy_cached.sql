--
-- Name: v_ncbi_taxonomy_cached; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_ncbi_taxonomy_cached AS
 SELECT t_ncbi_taxonomy_cached.tax_id,
    t_ncbi_taxonomy_cached.name,
    t_ncbi_taxonomy_cached.rank,
    t_ncbi_taxonomy_cached.parent_tax_id,
    t_ncbi_taxonomy_cached.synonyms,
    t_ncbi_taxonomy_cached.synonym_list
   FROM ont.t_ncbi_taxonomy_cached;


ALTER TABLE ont.v_ncbi_taxonomy_cached OWNER TO d3l243;

--
-- Name: TABLE v_ncbi_taxonomy_cached; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_ncbi_taxonomy_cached TO readaccess;

