--
-- Name: v_bto_tissue_report; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_bto_tissue_report AS
 SELECT term_name AS tissue,
    identifier,
    is_leaf,
    parent_term_name AS parent_tissue,
    parent_term_id AS parent_id,
    grandparent_term_name AS grandparent_tissue,
    grandparent_term_id AS grandparent_id,
    synonyms,
    children,
    usage_last_12_months AS usage,
    usage_all_time,
    entry_id
   FROM ont.t_cv_bto bto;


ALTER VIEW ont.v_bto_tissue_report OWNER TO d3l243;

--
-- Name: TABLE v_bto_tissue_report; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_bto_tissue_report TO readaccess;
GRANT SELECT ON TABLE ont.v_bto_tissue_report TO writeaccess;

