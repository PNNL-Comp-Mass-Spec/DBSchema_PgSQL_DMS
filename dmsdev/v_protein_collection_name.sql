--
-- Name: v_protein_collection_name; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_protein_collection_name AS
 SELECT lookupq.collection_name AS name,
    lookupq.type,
        CASE
            WHEN (COALESCE(org.organism_db_name, ''::public.citext) OPERATOR(public.=) lookupq.collection_name) THEN
            CASE
                WHEN (COALESCE(lookupq.description, ''::public.citext) OPERATOR(public.=) ''::public.citext) THEN 'PREFERRED'::public.citext
                ELSE ((('PREFERRED: '::public.citext)::text || (lookupq.description)::text))::public.citext
            END
            ELSE lookupq.description
        END AS description,
        CASE
            WHEN (lookupq.type OPERATOR(public.=) ANY (ARRAY['Internal_standard'::public.citext, 'contaminant'::public.citext, 'old_contaminant'::public.citext])) THEN NULL::integer
            ELSE pcu.job_usage_count_last12months
        END AS usage_last_12_months,
        CASE
            WHEN (lookupq.type OPERATOR(public.=) ANY (ARRAY['Internal_standard'::public.citext, 'contaminant'::public.citext, 'old_contaminant'::public.citext])) THEN NULL::integer
            ELSE pcu.job_usage_count
        END AS usage_all_years,
        CASE
            WHEN (lookupq.type OPERATOR(public.=) ANY (ARRAY['Internal_standard'::public.citext, 'contaminant'::public.citext, 'old_contaminant'::public.citext])) THEN NULL::date
            ELSE (pcu.most_recently_used)::date
        END AS most_recent_usage,
    lookupq.entries,
    lookupq.organism_name,
    lookupq.protein_collection_id AS id
   FROM ((( SELECT pc.collection_name,
            pct.type,
            pc.description,
            pc.num_proteins AS entries,
                CASE
                    WHEN (pct.type OPERATOR(public.=) ANY (ARRAY['Internal_Standard'::public.citext, 'contaminant'::public.citext, 'old_contaminant'::public.citext])) THEN ''::public.citext
                    ELSE org_1.organism
                END AS organism_name,
            pc.protein_collection_id,
                CASE
                    WHEN (pct.type OPERATOR(public.=) 'Internal_Standard'::public.citext) THEN 1
                    WHEN (pct.type OPERATOR(public.=) ANY (ARRAY['contaminant'::public.citext, 'old_contaminant'::public.citext])) THEN 2
                    ELSE 0
                END AS typesortorder
           FROM ((((pc.t_protein_collections pc
             JOIN pc.t_collection_organism_xref orgxref ON ((pc.protein_collection_id = orgxref.protein_collection_id)))
             JOIN pc.t_protein_collection_types pct ON ((pc.collection_type_id = pct.collection_type_id)))
             JOIN pc.t_protein_collection_states pcs ON ((pc.collection_state_id = pcs.collection_state_id)))
             JOIN public.t_organisms org_1 ON ((orgxref.organism_id = org_1.organism_id)))
          WHERE (COALESCE(pcs.state, ''::public.citext) OPERATOR(public.<>) 'Retired'::public.citext)) lookupq
     LEFT JOIN public.t_organisms org ON ((lookupq.organism_name OPERATOR(public.=) org.organism)))
     LEFT JOIN public.t_protein_collection_usage pcu ON ((lookupq.protein_collection_id = pcu.protein_collection_id)))
  GROUP BY lookupq.collection_name, lookupq.type, lookupq.description, lookupq.entries, lookupq.organism_name, lookupq.protein_collection_id, lookupq.typesortorder, pcu.most_recently_used, pcu.job_usage_count, pcu.job_usage_count_last12months, org.organism_db_name;


ALTER VIEW public.v_protein_collection_name OWNER TO d3l243;

--
-- Name: TABLE v_protein_collection_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_protein_collection_name TO readaccess;
GRANT SELECT ON TABLE public.v_protein_collection_name TO writeaccess;

