--
-- Name: v_cv_psi_ms; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_cv_psi_ms AS
 SELECT t_cv_ms.entry_id,
    t_cv_ms.term_name,
    t_cv_ms.identifier,
    t_cv_ms.is_leaf,
    t_cv_ms.parent_term_name,
    t_cv_ms.parent_term_id,
    t_cv_ms.grandparent_term_name,
    t_cv_ms.grandparent_term_id
   FROM ont.t_cv_ms;


ALTER TABLE ont.v_cv_psi_ms OWNER TO d3l243;

--
-- Name: TABLE v_cv_psi_ms; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_cv_psi_ms TO readaccess;

