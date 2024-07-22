--
-- Name: v_protein_collection_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_protein_collection_detail_report AS
 SELECT lookupq.protein_collection_id AS id,
    lookupq.name,
        CASE
            WHEN (COALESCE(org.organism_db_name, ''::public.citext) OPERATOR(public.=) lookupq.name) THEN
            CASE
                WHEN (COALESCE(lookupq.description, ''::public.citext) OPERATOR(public.=) ''::public.citext) THEN 'PREFERRED'::public.citext
                ELSE ((('PREFERRED: '::public.citext)::text || (lookupq.description)::text))::public.citext
            END
            ELSE lookupq.description
        END AS description,
    lookupq.organism_name,
    (((lookupq.state)::text || '; '::text) || (lookupq.state_description)::text) AS "?column?",
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
    lookupq.source
   FROM ((( SELECT cp.name,
            cp.type,
            cp.description,
            cp.source,
            cp.entries,
            cp.residues,
            cp.internal_standard_or_contaminant,
            cp.protein_collection_id,
                CASE
                    WHEN (cp.internal_standard_or_contaminant > 0) THEN ''::public.citext
                    ELSE cp.organism_name
                END AS organism_name,
            cp.state,
            cp.state_description,
            cp.includes_contaminants,
            cp.file_size_mb
           FROM ( SELECT pc.collection_name AS name,
                    pctypes.type,
                    pc.description,
                    pc.source,
                    pc.num_proteins AS entries,
                    pc.num_residues AS residues,
                        CASE
                            WHEN (pctypes.type OPERATOR(public.=) ANY (ARRAY['Internal_Standard'::public.citext, 'contaminant'::public.citext, 'old_contaminant'::public.citext])) THEN 1
                            ELSE 0
                        END AS internal_standard_or_contaminant,
                    orglist.organism AS organism_name,
                    pc.protein_collection_id,
                    pcs.state,
                    pcs.description AS state_description,
                    pc.includes_contaminants,
                    round((((aof.file_size_bytes)::numeric / 1024.0) / (1024)::numeric), 2) AS file_size_mb
                   FROM (((((pc.t_protein_collections pc
                     JOIN pc.t_collection_organism_xref orgxref ON ((pc.protein_collection_id = orgxref.protein_collection_id)))
                     JOIN public.t_organisms orglist ON ((orgxref.organism_id = orglist.organism_id)))
                     JOIN pc.t_protein_collection_types pctypes ON ((pc.collection_type_id = pctypes.collection_type_id)))
                     JOIN pc.t_protein_collection_states pcs ON ((pc.collection_state_id = pcs.collection_state_id)))
                     LEFT JOIN pc.t_archived_output_files aof ON ((pc.authentication_hash OPERATOR(public.=) aof.authentication_hash)))) cp) lookupq
     LEFT JOIN public.t_organisms org ON ((lookupq.organism_name OPERATOR(public.=) org.organism)))
     LEFT JOIN public.t_protein_collection_usage pcu ON ((lookupq.protein_collection_id = pcu.protein_collection_id)))
  GROUP BY lookupq.protein_collection_id, lookupq.name, lookupq.description, lookupq.organism_name, lookupq.state, lookupq.state_description, lookupq.entries, lookupq.residues, pcu.job_usage_count_last12months, pcu.job_usage_count, pcu.most_recently_used, lookupq.includes_contaminants, lookupq.file_size_mb, lookupq.type, lookupq.source, lookupq.internal_standard_or_contaminant, org.organism_db_name;


ALTER VIEW public.v_protein_collection_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_protein_collection_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_protein_collection_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_protein_collection_detail_report TO writeaccess;

