--
-- Name: v_newt_terms; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_newt_terms AS
 SELECT term_name,
    identifier,
    term_pk,
    is_leaf,
    rank,
    parent_term_name,
    parent_term_id AS parent_term_identifier,
    grandparent_term_name,
    grandparent_term_id AS grandparent_term_identifier,
    common_name,
    synonym,
    mnemonic
   FROM ont.t_cv_newt;


ALTER VIEW ont.v_newt_terms OWNER TO d3l243;

--
-- Name: TABLE v_newt_terms; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_newt_terms TO readaccess;
GRANT SELECT ON TABLE ont.v_newt_terms TO writeaccess;

