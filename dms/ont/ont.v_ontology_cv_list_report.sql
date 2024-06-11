--
-- Name: v_ontology_cv_list_report; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_ontology_cv_list_report AS
 SELECT source,
    identifier,
    term_name,
    is_leaf,
    parent_term_name,
    parent_term_id,
    grandparent_term_name,
    grandparent_term_id,
    term_pk
   FROM ont.t_cv_union_cached;


ALTER VIEW ont.v_ontology_cv_list_report OWNER TO d3l243;

--
-- Name: TABLE v_ontology_cv_list_report; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_ontology_cv_list_report TO readaccess;
GRANT SELECT ON TABLE ont.v_ontology_cv_list_report TO writeaccess;

