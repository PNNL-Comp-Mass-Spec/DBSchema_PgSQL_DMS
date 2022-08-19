--
-- Name: v_bto_tissue_report; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_bto_tissue_report AS
 SELECT bto.term_name AS tissue,
    bto.identifier,
    bto.is_leaf,
    bto.parent_term_name AS parent_tissue,
    bto.parent_term_id AS parent_id,
    bto.grandparent_term_name AS grandparent_tissue,
    bto.grandparent_term_id AS grandparent_id,
    bto.synonyms,
    bto.children,
    bto.usage_last_12_months AS usage,
    bto.usage_all_time,
    bto.entry_id
   FROM ont.t_cv_bto bto;


ALTER TABLE ont.v_bto_tissue_report OWNER TO d3l243;

--
-- Name: TABLE v_bto_tissue_report; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_bto_tissue_report TO readaccess;

