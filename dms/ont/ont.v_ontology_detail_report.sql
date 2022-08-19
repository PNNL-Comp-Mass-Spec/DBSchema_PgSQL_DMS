--
-- Name: v_ontology_detail_report; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_ontology_detail_report AS
 SELECT t.term_pk,
    t.term_name,
    t.identifier,
    t.definition,
    t.namespace,
    t.is_obsolete,
    t.is_root_term,
    t.is_leaf,
    t.ontology_id,
    t.ontology_shortname,
    t.ontology_fullname,
    l.parent_term_name,
    l.parent_term_identifier,
    l.parent_term_pk,
    l.grandparent_term_name,
    l.grandparent_term_identifier,
    l.grandparent_term_pk,
    l.predicate_term_pk
   FROM (ont.v_term t
     JOIN ont.v_term_lineage l ON ((t.term_pk OPERATOR(public.=) l.term_pk)));


ALTER TABLE ont.v_ontology_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_ontology_detail_report; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_ontology_detail_report TO readaccess;
GRANT SELECT ON TABLE ont.v_ontology_detail_report TO writeaccess;

