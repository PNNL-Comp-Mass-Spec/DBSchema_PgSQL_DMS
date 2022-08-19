--
-- Name: v_helper_newt_list_report; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_helper_newt_list_report AS
 SELECT v_cv_newt.identifier,
    v_cv_newt.term_name,
    v_cv_newt.parent_term_name AS parent,
    v_cv_newt.grandparent_term_name AS grandparent,
    v_cv_newt.is_leaf
   FROM ont.v_cv_newt;


ALTER TABLE ont.v_helper_newt_list_report OWNER TO d3l243;

--
-- Name: TABLE v_helper_newt_list_report; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_helper_newt_list_report TO readaccess;
GRANT SELECT ON TABLE ont.v_helper_newt_list_report TO writeaccess;

