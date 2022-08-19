--
-- Name: v_ontology_list_report; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_ontology_list_report AS
 SELECT v_cv_union.source,
    v_cv_union.term_name,
    v_cv_union.identifier,
    v_cv_union.is_leaf,
    v_cv_union.parent_term_name,
    v_cv_union.parent_term_id,
    v_cv_union.grandparent_term_name,
    v_cv_union.grandparent_term_id,
    v_cv_union.term_pk
   FROM ont.v_cv_union;


ALTER TABLE ont.v_ontology_list_report OWNER TO d3l243;

--
-- Name: TABLE v_ontology_list_report; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_ontology_list_report TO readaccess;

