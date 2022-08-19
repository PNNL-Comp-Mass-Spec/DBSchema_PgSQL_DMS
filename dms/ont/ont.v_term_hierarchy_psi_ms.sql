--
-- Name: v_term_hierarchy_psi_ms; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_term_hierarchy_psi_ms AS
 WITH RECURSIVE termhierarchy AS (
         SELECT child.namespace,
            child.term_name,
            child.identifier,
            child.term_pk,
            child.is_obsolete,
            child.is_leaf,
            NULL::public.citext AS parent_name,
            NULL::public.citext AS parent_identifier,
            NULL::public.citext AS parent_pk,
            0 AS level
           FROM ont.t_term child
          WHERE ((child.is_root_term = 1) AND (child.namespace OPERATOR(public.=) 'MS'::public.citext))
        UNION ALL
         SELECT child.namespace,
            child.term_name,
            child.identifier,
            child.term_pk,
            child.is_obsolete,
            child.is_leaf,
            termhierarchy_1.term_name AS parent_name,
            termhierarchy_1.identifier AS parent_identifier,
            t_term_relationship.object_term_pk AS parent_pk,
            (termhierarchy_1.level + 1) AS level
           FROM ((ont.t_term child
             JOIN ont.t_term_relationship ON ((child.term_pk OPERATOR(public.=) t_term_relationship.subject_term_pk)))
             JOIN termhierarchy termhierarchy_1 ON ((t_term_relationship.object_term_pk OPERATOR(public.=) termhierarchy_1.term_pk)))
          WHERE (child.namespace OPERATOR(public.=) 'MS'::public.citext)
        )
 SELECT termhierarchy.namespace,
    termhierarchy.term_name,
    termhierarchy.identifier,
    termhierarchy.term_pk,
    termhierarchy.is_obsolete,
    termhierarchy.is_leaf,
    termhierarchy.parent_name,
    termhierarchy.parent_identifier,
    termhierarchy.parent_pk,
    termhierarchy.level
   FROM termhierarchy;


ALTER TABLE ont.v_term_hierarchy_psi_ms OWNER TO d3l243;

--
-- Name: VIEW v_term_hierarchy_psi_ms; Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON VIEW ont.v_term_hierarchy_psi_ms IS 'This view uses a recursive query. It is elegant, but not efficient since the "T_Term" and "T_Term_Relationship" tables are so large. Use view V_CV_PSI_MS instead. Note that namespace "MS" supersedes namespace "PSI-MS". Note that namespace "MS" supersedes namespace "PSI-MS"';

--
-- Name: TABLE v_term_hierarchy_psi_ms; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_term_hierarchy_psi_ms TO readaccess;
GRANT SELECT ON TABLE ont.v_term_hierarchy_psi_ms TO writeaccess;

