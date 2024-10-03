--
-- Name: v_protein_collection_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_protein_collection_detail_report AS
 SELECT lookupq.protein_collection_id AS id,
    lookupq.collection_name AS name,
    lookupq.description,
    string_agg((lookupq.organism)::text, ', '::text ORDER BY (lookupq.organism)::text) AS organism_name,
    lookupq.state,
    lookupq.entries,
    lookupq.residues,
        CASE
            WHEN (lookupq.internal_standard_or_contaminant > 0) THEN NULL::integer
            ELSE pcu.job_usage_count_last12months
        END AS usage_last_12_months,
        CASE
            WHEN (lookupq.internal_standard_or_contaminant > 0) THEN NULL::integer
            ELSE pcu.job_usage_count
        END AS usage_all_years,
        CASE
            WHEN (lookupq.internal_standard_or_contaminant > 0) THEN NULL::date
            ELSE (pcu.most_recently_used)::date
        END AS most_recent_usage,
    lookupq.includes_contaminants,
    lookupq.file_size_mb,
    lookupq.type,
    lookupq.source,
    lookupq.annotation_type
   FROM (( SELECT DISTINCT pc.protein_collection_id,
            pc.collection_name,
            pc.description,
            orglist.organism,
            (((pcs.state)::text || '; '::text) || (pcs.description)::text) AS state,
            pc.num_proteins AS entries,
            pc.num_residues AS residues,
            pc.includes_contaminants,
            round((((aof.file_size_bytes)::numeric / 1024.0) / 1024.0), 2) AS file_size_mb,
                CASE
                    WHEN (pctypes.type OPERATOR(public.=) ANY (ARRAY['Internal_Standard'::public.citext, 'contaminant'::public.citext, 'old_contaminant'::public.citext])) THEN 1
                    ELSE 0
                END AS internal_standard_or_contaminant,
            pctypes.type,
            pc.source,
            (((auth.name)::text || ' - '::text) || (antypes.type_name)::text) AS annotation_type
           FROM (((((((pc.t_protein_collections pc
             JOIN pc.t_collection_organism_xref orgxref ON ((pc.protein_collection_id = orgxref.protein_collection_id)))
             JOIN public.t_organisms orglist ON ((orgxref.organism_id = orglist.organism_id)))
             JOIN pc.t_protein_collection_states pcs ON ((pc.collection_state_id = pcs.collection_state_id)))
             JOIN pc.t_protein_collection_types pctypes ON ((pc.collection_type_id = pctypes.collection_type_id)))
             JOIN pc.t_annotation_types antypes ON ((pc.primary_annotation_type_id = antypes.annotation_type_id)))
             JOIN pc.t_naming_authorities auth ON ((auth.authority_id = antypes.authority_id)))
             LEFT JOIN pc.t_archived_output_files aof ON (((pc.authentication_hash OPERATOR(public.=) aof.authentication_hash) AND (aof.archived_file_state_id <> 3))))) lookupq
     LEFT JOIN public.t_protein_collection_usage pcu ON ((lookupq.protein_collection_id = pcu.protein_collection_id)))
  GROUP BY lookupq.protein_collection_id, lookupq.collection_name, lookupq.description, lookupq.state, lookupq.entries, lookupq.residues, lookupq.includes_contaminants, lookupq.file_size_mb, lookupq.internal_standard_or_contaminant, lookupq.type, lookupq.source, lookupq.annotation_type, pcu.job_usage_count_last12months, pcu.job_usage_count, pcu.most_recently_used;


ALTER VIEW public.v_protein_collection_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_protein_collection_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_protein_collection_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_protein_collection_detail_report TO writeaccess;

