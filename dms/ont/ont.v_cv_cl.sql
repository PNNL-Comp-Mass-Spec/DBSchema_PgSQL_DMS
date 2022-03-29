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
    t_cv_cl.grand_parent_term_name,
    t_cv_cl.grand_parent_term_id
   FROM ont.t_cv_cl;


ALTER TABLE ont.v_cv_cl OWNER TO d3l243;

