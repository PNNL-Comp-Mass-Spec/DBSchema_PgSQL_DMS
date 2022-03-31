--
-- Name: v_cv_envo; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_cv_envo AS
 SELECT t_cv_envo.entry_id,
    t_cv_envo.term_name,
    t_cv_envo.identifier,
    t_cv_envo.is_leaf,
    t_cv_envo.parent_term_name,
    t_cv_envo.parent_term_id,
    t_cv_envo.grandparent_term_name,
    t_cv_envo.grandparent_term_id,
    t_cv_envo.synonyms
   FROM ont.t_cv_envo;


ALTER TABLE ont.v_cv_envo OWNER TO d3l243;

