--
-- Name: v_ontology_list_report; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_ontology_list_report AS
 SELECT ontology_short_name AS ontology,
    identifier,
    term_name,
    is_leaf,
    definition,
    namespace,
    is_obsolete,
    is_root_term,
    term_pk
   FROM ont.v_term;


ALTER VIEW ont.v_ontology_list_report OWNER TO d3l243;

--
-- Name: TABLE v_ontology_list_report; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_ontology_list_report TO readaccess;
GRANT SELECT ON TABLE ont.v_ontology_list_report TO writeaccess;

