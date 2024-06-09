--
-- Name: v_newt_list_report; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_newt_list_report AS
 SELECT term_name,
    identifier,
    is_leaf,
    parent_term_name,
    parent_term_id,
    grandparent_term_name,
    grandparent_term_id,
    children
    rank,
    common_name,
    synonym,
    mnemonic,
    term_pk
   FROM ont.t_cv_newt;


ALTER VIEW ont.v_newt_list_report OWNER TO d3l243;

--
-- Name: TABLE v_newt_list_report; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_newt_list_report TO readaccess;
GRANT SELECT ON TABLE ont.v_newt_list_report TO writeaccess;

