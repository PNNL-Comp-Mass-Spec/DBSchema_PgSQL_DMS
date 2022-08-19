--
-- Name: v_cv_psi_mi; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_cv_psi_mi AS
 SELECT t_cv_mi.entry_id,
    t_cv_mi.term_name,
    t_cv_mi.identifier,
    t_cv_mi.is_leaf,
    t_cv_mi.parent_term_name,
    t_cv_mi.parent_term_id,
    t_cv_mi.grandparent_term_name,
    t_cv_mi.grandparent_term_id
   FROM ont.t_cv_mi;


ALTER TABLE ont.v_cv_psi_mi OWNER TO d3l243;

--
-- Name: TABLE v_cv_psi_mi; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_cv_psi_mi TO readaccess;

