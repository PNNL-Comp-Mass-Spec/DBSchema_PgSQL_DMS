--
-- Name: v_term_leaf_nodes; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_term_leaf_nodes AS
 SELECT v_term.term_pk,
    v_term.term_name,
    v_term.identifier,
    v_term.definition,
    v_term.namespace,
    v_term.is_obsolete,
    v_term.is_root_term,
    v_term.is_leaf,
    v_term.ontology_id,
    v_term.ontology_shortname,
    v_term.ontology_fullname
   FROM ont.v_term
  WHERE (v_term.is_leaf = 1);


ALTER TABLE ont.v_term_leaf_nodes OWNER TO d3l243;

--
-- Name: TABLE v_term_leaf_nodes; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_term_leaf_nodes TO readaccess;
GRANT SELECT ON TABLE ont.v_term_leaf_nodes TO writeaccess;

