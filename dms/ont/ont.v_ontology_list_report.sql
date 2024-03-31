--
-- Name: v_ontology_list_report; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_ontology_list_report AS
 SELECT source,
    term_name,
    identifier,
    is_leaf,
    parent_term_name,
    parent_term_id,
    grandparent_term_name,
    grandparent_term_id,
    term_pk
   FROM ont.v_cv_union;


ALTER VIEW ont.v_ontology_list_report OWNER TO d3l243;

--
-- Name: TABLE v_ontology_list_report; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_ontology_list_report TO readaccess;
GRANT SELECT ON TABLE ont.v_ontology_list_report TO writeaccess;

