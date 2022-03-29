--
-- Name: v_bto_tissue_report; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_bto_tissue_report AS
 SELECT bto.term_name AS tissue,
    bto.identifier,
    bto.is_leaf AS "Is Leaf",
    bto.parent_term_name AS "Parent Tissue",
    bto.parent_term_id AS "Parent ID",
    bto.grand_parent_term_name AS "Grandparent Tissue",
    bto.grand_parent_term_id AS "Grandparent ID",
    bto.synonyms,
    bto.children,
    bto.usage_last_12_months AS "Usage",
    bto.usage_all_time AS "Usage (all time)",
    bto.entry_id
   FROM ont.t_cv_bto bto;


ALTER TABLE ont.v_bto_tissue_report OWNER TO d3l243;

