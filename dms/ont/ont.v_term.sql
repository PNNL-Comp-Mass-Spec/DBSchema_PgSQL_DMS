--
-- Name: v_term; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_term AS
 SELECT t.term_pk,
    t.term_name,
    t.identifier,
    t.definition,
    t.namespace,
    t.is_obsolete,
    t.is_root_term,
    t.is_leaf,
    t.ontology_id,
    o.short_name AS ontology_shortname,
    o.full_name AS ontology_fullname
   FROM (ont.t_ontology o
     JOIN ont.t_term t ON ((o.ontology_id = t.ontology_id)));


ALTER TABLE ont.v_term OWNER TO d3l243;

--
-- Name: TABLE v_term; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_term TO readaccess;
GRANT SELECT ON TABLE ont.v_term TO writeaccess;

