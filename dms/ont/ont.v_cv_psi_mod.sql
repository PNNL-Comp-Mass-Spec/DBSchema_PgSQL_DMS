--
-- Name: v_cv_psi_mod; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_cv_psi_mod AS
 SELECT t_cv_mod.entry_id,
    t_cv_mod.term_name,
    t_cv_mod.identifier,
    t_cv_mod.is_leaf,
    t_cv_mod.parent_term_name,
    t_cv_mod.parent_term_id,
    t_cv_mod.grandparent_term_name,
    t_cv_mod.grandparent_term_id
   FROM ont.t_cv_mod;


ALTER VIEW ont.v_cv_psi_mod OWNER TO d3l243;

--
-- Name: TABLE v_cv_psi_mod; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_cv_psi_mod TO readaccess;
GRANT SELECT ON TABLE ont.v_cv_psi_mod TO writeaccess;

