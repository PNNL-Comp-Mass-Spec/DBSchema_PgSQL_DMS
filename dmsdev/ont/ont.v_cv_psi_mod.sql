--
-- Name: v_cv_psi_mod; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_cv_psi_mod AS
 SELECT entry_id,
    term_name,
    identifier,
    is_leaf,
    parent_term_name,
    parent_term_id,
    grandparent_term_name,
    grandparent_term_id
   FROM ont.t_cv_mod;


ALTER VIEW ont.v_cv_psi_mod OWNER TO d3l243;

--
-- Name: TABLE v_cv_psi_mod; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_cv_psi_mod TO readaccess;
GRANT SELECT ON TABLE ont.v_cv_psi_mod TO writeaccess;
