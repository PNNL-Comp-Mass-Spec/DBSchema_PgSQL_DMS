--
-- Name: v_newt_terms; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_newt_terms AS
 SELECT term_name,
    identifier,
    term_pk,
    is_leaf,
    parent_term_name,
    parent_term_identifier,
    grandparent_term_name,
    grandparent_term_identifier
   FROM ont.v_term_lineage
  WHERE ((ontology OPERATOR(public.=) 'NEWT'::public.citext) AND (is_obsolete = 0) AND (identifier OPERATOR(public.~) similar_to_escape(('[0-9]%'::public.citext)::text)));


ALTER VIEW ont.v_newt_terms OWNER TO d3l243;

--
-- Name: TABLE v_newt_terms; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_newt_terms TO readaccess;
GRANT SELECT ON TABLE ont.v_newt_terms TO writeaccess;

