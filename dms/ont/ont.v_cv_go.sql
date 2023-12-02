--
-- Name: v_cv_go; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_cv_go AS
 SELECT t_cv_go.entry_id,
    t_cv_go.term_name,
    t_cv_go.identifier,
    t_cv_go.is_leaf,
    t_cv_go.parent_term_name,
    t_cv_go.parent_term_id,
    t_cv_go.grandparent_term_name,
    t_cv_go.grandparent_term_id
   FROM ont.t_cv_go;


ALTER VIEW ont.v_cv_go OWNER TO d3l243;

--
-- Name: TABLE v_cv_go; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_cv_go TO readaccess;
GRANT SELECT ON TABLE ont.v_cv_go TO writeaccess;

