--
-- Name: v_term_leaf_nodes; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_term_leaf_nodes AS
 SELECT term_pk,
    term_name,
    identifier,
    definition,
    namespace,
    is_obsolete,
    is_root_term,
    is_leaf,
    ontology_id,
    ontology_short_name,
    ontology_full_name
   FROM ont.v_term
  WHERE (is_leaf = 1);


ALTER VIEW ont.v_term_leaf_nodes OWNER TO d3l243;

--
-- Name: TABLE v_term_leaf_nodes; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_term_leaf_nodes TO readaccess;
GRANT SELECT ON TABLE ont.v_term_leaf_nodes TO writeaccess;

