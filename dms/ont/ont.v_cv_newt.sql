--
-- Name: v_cv_newt; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_cv_newt AS
 SELECT t_cv_newt.entry_id,
    t_cv_newt.term_name,
    t_cv_newt.identifier,
    t_cv_newt.is_leaf,
    t_cv_newt.parent_term_name,
    t_cv_newt.parent_term_id,
    t_cv_newt.grandparent_term_name,
    t_cv_newt.grandparent_term_id
   FROM ont.t_cv_newt;


ALTER TABLE ont.v_cv_newt OWNER TO d3l243;

