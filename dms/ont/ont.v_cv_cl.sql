--
-- Name: v_cv_cl; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_cv_cl AS
 SELECT t_cv_cl.entry_id,
    t_cv_cl.term_name,
    t_cv_cl.identifier,
    t_cv_cl.is_leaf,
    t_cv_cl.parent_term_name,
    t_cv_cl.parent_term_id,
    t_cv_cl.grandparent_term_name,
    t_cv_cl.grandparent_term_id
   FROM ont.t_cv_cl;


ALTER VIEW ont.v_cv_cl OWNER TO d3l243;

--
-- Name: TABLE v_cv_cl; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_cv_cl TO readaccess;
GRANT SELECT ON TABLE ont.v_cv_cl TO writeaccess;

