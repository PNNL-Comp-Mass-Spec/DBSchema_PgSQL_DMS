--
-- Name: v_newt_lineage; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_newt_lineage AS
 SELECT n.term_pk,
    n.term_name,
    n.identifier,
    n.parent_term_name,
    n.parent_term_id AS parent_term_identifier,
    n.grandparent_term_name,
    n.grandparent_term_id AS grandparent_term_identifier,
    n.is_leaf,
    n.rank,
    n.common_name,
    n.synonym,
    n.mnemonic,
    parent.term_pk AS parent_term_pk,
    grandparent.term_pk AS grandparent_term_pk
   FROM ((ont.t_cv_newt n
     LEFT JOIN ont.t_cv_newt parent ON ((n.parent_term_id = parent.identifier)))
     LEFT JOIN ont.t_cv_newt grandparent ON ((n.grandparent_term_id = grandparent.identifier)));


ALTER VIEW ont.v_newt_lineage OWNER TO d3l243;

--
-- Name: TABLE v_newt_lineage; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_newt_lineage TO readaccess;
GRANT SELECT ON TABLE ont.v_newt_lineage TO writeaccess;

