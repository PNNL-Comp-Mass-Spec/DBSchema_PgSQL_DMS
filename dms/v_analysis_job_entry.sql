--
-- Name: v_analysis_job_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_entry AS
 SELECT j.job,
    j.priority,
    tool.analysis_tool AS tool_name,
    ds.dataset,
    j.param_file_name AS param_file,
    j.settings_file_name AS settings_file,
    org.organism,
    j.organism_db_name AS organism_db,
    j.owner,
    j.comment,
    j.special_processing,
    j.batch_id,
    j.assigned_processor_name,
    j.protein_collection_list AS prot_coll_name_list,
    j.protein_options_list AS prot_coll_options_list,
    asn.job_state AS state_name,
        CASE j.propagation_mode
            WHEN 0 THEN 'Export'::text
            ELSE 'No Export'::text
        END AS propagation_mode,
    ajpg.group_name AS associated_processor_group
   FROM ((public.t_analysis_job_processor_group ajpg
     JOIN public.t_analysis_job_processor_group_associations ajpga ON ((ajpg.group_id = ajpga.group_id)))
     RIGHT JOIN ((((public.t_analysis_job j
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_organisms org ON ((j.organism_id = org.organism_id)))
     JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id)))
     JOIN public.t_analysis_job_state asn ON ((j.job_state_id = asn.job_state_id))) ON ((ajpga.job = j.job)));


ALTER TABLE public.v_analysis_job_entry OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_entry TO readaccess;

