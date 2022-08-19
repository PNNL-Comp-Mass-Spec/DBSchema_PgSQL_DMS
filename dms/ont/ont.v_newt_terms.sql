--
-- Name: v_newt_terms; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_newt_terms AS
 SELECT v_term_lineage.term_name,
    v_term_lineage.identifier,
    v_term_lineage.term_pk,
    v_term_lineage.is_leaf,
    v_term_lineage.parent_term_name,
    v_term_lineage.parent_term_identifier,
    v_term_lineage.grandparent_term_name,
    v_term_lineage.grandparent_term_identifier
   FROM ont.v_term_lineage
  WHERE ((v_term_lineage.ontology OPERATOR(public.=) 'NEWT'::public.citext) AND (v_term_lineage.is_obsolete = 0) AND (v_term_lineage.identifier OPERATOR(public.~) similar_to_escape(('[0-9]%'::public.citext)::text)));


ALTER TABLE ont.v_newt_terms OWNER TO d3l243;

--
-- Name: TABLE v_newt_terms; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_newt_terms TO readaccess;

