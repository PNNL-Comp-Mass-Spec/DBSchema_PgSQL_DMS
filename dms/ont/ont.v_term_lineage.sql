--
-- Name: v_term_lineage; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_term_lineage AS
 SELECT child.term_pk,
    child.term_name,
    child.identifier,
    parent.term_name AS parent_term_name,
    parent.identifier AS parent_term_identifier,
    grandparent.term_name AS grandparent_term_name,
    grandparent.identifier AS grandparent_term_identifier,
    child.is_leaf,
    child.is_obsolete,
    child.namespace,
    child.ontology_id,
    o.short_name AS ontology,
    parentchildrelationship.predicate_term_pk,
    parent.term_pk AS parent_term_pk,
    grandparent.term_pk AS grandparent_term_pk
   FROM ((ont.t_ontology o
     JOIN ont.t_term child ON ((o.ontology_id = child.ontology_id)))
     LEFT JOIN ((ont.t_term grandparent
     JOIN ont.t_term_relationship grandparent_parent_relationship ON ((grandparent.term_pk OPERATOR(public.=) grandparent_parent_relationship.object_term_pk)))
     RIGHT JOIN (ont.t_term parent
     JOIN ont.t_term_relationship parentchildrelationship ON ((parent.term_pk OPERATOR(public.=) parentchildrelationship.object_term_pk))) ON ((grandparent_parent_relationship.subject_term_pk OPERATOR(public.=) parent.term_pk))) ON ((child.term_pk OPERATOR(public.=) parentchildrelationship.subject_term_pk)));


ALTER TABLE ont.v_term_lineage OWNER TO d3l243;

--
-- Name: TABLE v_term_lineage; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_term_lineage TO readaccess;

