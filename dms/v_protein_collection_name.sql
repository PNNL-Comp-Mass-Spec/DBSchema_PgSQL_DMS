--
-- Name: v_protein_collection_name; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_protein_collection_name AS
 SELECT lookupq.collection_name AS name,
    lookupq.state,
        CASE
            WHEN (COALESCE(org.organism_db_name, ''::public.citext) OPERATOR(public.=) lookupq.collection_name) THEN
            CASE
                WHEN (COALESCE(lookupq.description, ''::public.citext) OPERATOR(public.=) ''::public.citext) THEN 'PREFERRED'::public.citext
                ELSE ((('PREFERRED: '::public.citext)::text || (lookupq.description)::text))::public.citext
            END
            ELSE lookupq.description
        END AS description,
        CASE
            WHEN (lookupq.type OPERATOR(public.=) ANY (ARRAY['internal_standard'::public.citext, 'contaminant'::public.citext, 'old_contaminant'::public.citext])) THEN NULL::integer
            ELSE pcu.job_usage_count_last12months
        END AS usage_last_12_months,
        CASE
            WHEN (lookupq.type OPERATOR(public.=) ANY (ARRAY['internal_standard'::public.citext, 'contaminant'::public.citext, 'old_contaminant'::public.citext])) THEN NULL::integer
            ELSE pcu.job_usage_count
        END AS usage_all_years,
        CASE
            WHEN (lookupq.type OPERATOR(public.=) ANY (ARRAY['internal_standard'::public.citext, 'contaminant'::public.citext, 'old_contaminant'::public.citext])) THEN NULL::date
            ELSE (pcu.most_recently_used)::date
        END AS most_recent_usage,
    lookupq.entries,
    lookupq.organism_name,
    lookupq.type,
    lookupq.sort_weight,
    lookupq.protein_collection_id AS id
   FROM ((( SELECT pc.collection_name,
            pcs.state,
            pc.description,
            pc.num_proteins AS entries,
                CASE
                    WHEN (pct.type OPERATOR(public.=) ANY (ARRAY['internal_standard'::public.citext, 'contaminant'::public.citext, 'old_contaminant'::public.citext])) THEN ''::public.citext
                    ELSE org_1.organism
                END AS organism_name,
            pc.protein_collection_id,
                CASE
                    WHEN (pc.collection_state_id = ANY (ARRAY[1, 2, 3])) THEN
                    CASE
                        WHEN (pct.type OPERATOR(public.=) 'internal_standard'::public.citext) THEN 3
                        WHEN (pct.type OPERATOR(public.=) ANY (ARRAY['contaminant'::public.citext, 'old_contaminant'::public.citext])) THEN 2
                        ELSE 1
                    END
                    ELSE
                    CASE
                        WHEN (pct.type OPERATOR(public.=) 'internal_standard'::public.citext) THEN 6
                        WHEN (pct.type OPERATOR(public.=) ANY (ARRAY['contaminant'::public.citext, 'old_contaminant'::public.citext])) THEN 5
                        ELSE 4
                    END
                END AS sort_weight,
            pct.type
           FROM ((((pc.t_protein_collections pc
             JOIN pc.t_collection_organism_xref orgxref ON ((pc.protein_collection_id = orgxref.protein_collection_id)))
             JOIN pc.t_protein_collection_types pct ON ((pc.collection_type_id = pct.collection_type_id)))
             JOIN pc.t_protein_collection_states pcs ON ((pc.collection_state_id = pcs.collection_state_id)))
             JOIN public.t_organisms org_1 ON ((orgxref.organism_id = org_1.organism_id)))
          WHERE (NOT (pcs.collection_state_id = ANY (ARRAY[0, 4, 5])))) lookupq
     LEFT JOIN public.t_organisms org ON ((lookupq.organism_name OPERATOR(public.=) org.organism)))
     LEFT JOIN public.t_protein_collection_usage pcu ON ((lookupq.protein_collection_id = pcu.protein_collection_id)))
  GROUP BY lookupq.collection_name, lookupq.state, org.organism_db_name, lookupq.description, pcu.job_usage_count, pcu.job_usage_count_last12months, pcu.most_recently_used, lookupq.entries, lookupq.organism_name, lookupq.type, lookupq.sort_weight, lookupq.protein_collection_id;


ALTER VIEW public.v_protein_collection_name OWNER TO d3l243;

--
-- Name: TABLE v_protein_collection_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_protein_collection_name TO readaccess;
GRANT SELECT ON TABLE public.v_protein_collection_name TO writeaccess;

