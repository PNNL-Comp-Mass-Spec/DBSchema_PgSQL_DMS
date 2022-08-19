--
-- Name: v_cv_bto; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_cv_bto AS
 SELECT t_cv_bto.entry_id,
    t_cv_bto.term_name,
    t_cv_bto.identifier,
    t_cv_bto.is_leaf,
    t_cv_bto.parent_term_name,
    t_cv_bto.parent_term_id,
    t_cv_bto.grandparent_term_name,
    t_cv_bto.grandparent_term_id,
    t_cv_bto.synonyms
   FROM ont.t_cv_bto;


ALTER TABLE ont.v_cv_bto OWNER TO d3l243;

--
-- Name: TABLE v_cv_bto; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_cv_bto TO readaccess;

