--
-- Name: v_cv_pride; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_cv_pride AS
 SELECT t_cv_pride.entry_id,
    t_cv_pride.term_name,
    t_cv_pride.identifier,
    t_cv_pride.is_leaf,
    t_cv_pride.parent_term_name,
    t_cv_pride.parent_term_id,
    t_cv_pride.grandparent_term_name,
    t_cv_pride.grandparent_term_id
   FROM ont.t_cv_pride;


ALTER TABLE ont.v_cv_pride OWNER TO d3l243;

--
-- Name: TABLE v_cv_pride; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_cv_pride TO readaccess;
GRANT SELECT ON TABLE ont.v_cv_pride TO writeaccess;

