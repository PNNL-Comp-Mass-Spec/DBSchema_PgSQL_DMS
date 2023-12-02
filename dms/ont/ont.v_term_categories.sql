--
-- Name: v_term_categories; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_term_categories AS
 SELECT t.term_pk,
    t.ontology_id,
    o.short_name,
    t.term_name,
    t.identifier,
    t.definition,
    t.namespace,
    t.is_obsolete,
    t.is_root_term,
    t.is_leaf
   FROM (ont.t_ontology o
     JOIN ont.t_term t ON ((o.ontology_id = t.ontology_id)))
  WHERE (t.is_leaf = 0);


ALTER VIEW ont.v_term_categories OWNER TO d3l243;

--
-- Name: TABLE v_term_categories; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_term_categories TO readaccess;
GRANT SELECT ON TABLE ont.v_term_categories TO writeaccess;

