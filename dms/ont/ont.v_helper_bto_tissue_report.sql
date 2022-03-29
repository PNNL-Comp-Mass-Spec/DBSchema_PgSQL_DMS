--
-- Name: v_helper_bto_tissue_report; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_helper_bto_tissue_report AS
 SELECT t_cv_bto.term_name AS tissue,
    t_cv_bto.identifier,
    t_cv_bto.is_leaf AS "Is Leaf",
    t_cv_bto.parent_term_name AS "Parent Tissue",
    t_cv_bto.parent_term_id AS "Parent ID",
    t_cv_bto.grand_parent_term_name AS "Grandparent Tissue",
    t_cv_bto.grand_parent_term_id AS "Grandparent ID",
    t_cv_bto.synonyms,
    t_cv_bto.usage_last_12_months AS usage,
    t_cv_bto.usage_all_time AS "Usage (all time",
    t_cv_bto.entry_id
   FROM ont.t_cv_bto;


ALTER TABLE ont.v_helper_bto_tissue_report OWNER TO d3l243;

