--
-- Name: v_cv_doid; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_cv_doid AS
 SELECT t_cv_doid.entry_id,
    t_cv_doid.term_name,
    t_cv_doid.identifier,
    t_cv_doid.is_leaf,
    t_cv_doid.parent_term_name,
    t_cv_doid.parent_term_id,
    t_cv_doid.grandparent_term_name,
    t_cv_doid.grandparent_term_id
   FROM ont.t_cv_doid;


ALTER TABLE ont.v_cv_doid OWNER TO d3l243;

--
-- Name: TABLE v_cv_doid; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_cv_doid TO readaccess;

