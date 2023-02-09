--
-- Name: v_analysis_job_ex; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_ex AS
 SELECT j.job,
    tool.analysis_tool AS tool_name,
    ds.dataset,
    ds.folder_name AS dataset_folder_name,
    ((spath.vol_name_client)::text || (spath.storage_path)::text) AS dataset_storage_path,
    j.param_file_name,
    j.settings_file_name,
    tool.param_file_storage_path,
    j.organism_db_name,
    j.protein_collection_list,
    j.protein_options_list AS protein_options,
    org.organism_db_path AS organism_db_storage_path,
    j.job_state_id AS state_id,
    j.priority,
    j.comment,
    instname.instrument_class AS inst_class,
    j.owner_username AS owner
   FROM (((((public.t_analysis_job j
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_organisms org ON ((j.organism_id = org.organism_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)));


ALTER TABLE public.v_analysis_job_ex OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_ex; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_ex TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_ex TO writeaccess;

