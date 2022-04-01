--
-- Name: v_helper_bto_tissue_report; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_helper_bto_tissue_report AS
 SELECT t_cv_bto.term_name AS tissue,
    t_cv_bto.identifier,
    t_cv_bto.is_leaf,
    t_cv_bto.parent_term_name AS parent_tissue,
    t_cv_bto.parent_term_id AS parent_id,
    t_cv_bto.grandparent_term_name AS grandparent_tissue,
    t_cv_bto.grandparent_term_id AS grandparent_id,
    t_cv_bto.synonyms,
    t_cv_bto.usage_last_12_months AS usage,
    t_cv_bto.usage_all_time,
    t_cv_bto.entry_id
   FROM ont.t_cv_bto;


ALTER TABLE ont.v_helper_bto_tissue_report OWNER TO d3l243;

