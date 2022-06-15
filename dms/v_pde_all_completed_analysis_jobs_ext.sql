--
-- Name: v_pde_all_completed_analysis_jobs_ext; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_pde_all_completed_analysis_jobs_ext AS
 SELECT j.job AS analysis_id,
    ds.dataset AS dataset_name,
    e.experiment,
    t_campaign.campaign,
    j.finish AS completed,
    j.param_file_name AS param_file_used,
    t_organisms.organism,
    j.organism_db_name AS organism_database_used,
    j.protein_collection_list AS protein_collections_used,
    j.protein_options_list AS protein_collection_options,
    ((((v_dataset_folder_paths.dataset_folder_path)::text || '\'::text) || (j.results_folder_name)::text) || '\'::text) AS analysis_job_path,
    t_instrument_name.instrument AS instrument_name,
    j.request_id AS analysis_job_request_id,
    t_analysis_job_request.request_name AS analysis_job_request_name,
    ((((v_dataset_folder_paths.archive_folder_path)::text || '\'::text) || (j.results_folder_name)::text) || '\'::text) AS analysis_job_archive_path
   FROM (((((((((public.t_analysis_job j
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name ON ((ds.instrument_id = t_instrument_name.instrument_id)))
     JOIN public.t_storage_path ON ((ds.storage_path_id = t_storage_path.storage_path_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_analysis_tool ON ((j.analysis_tool_id = t_analysis_tool.analysis_tool_id)))
     JOIN public.t_campaign ON ((e.campaign_id = t_campaign.campaign_id)))
     JOIN public.t_analysis_job_request ON ((j.request_id = t_analysis_job_request.request_id)))
     JOIN public.t_organisms ON ((j.organism_id = t_organisms.organism_id)))
     JOIN public.v_dataset_folder_paths ON ((ds.dataset_id = v_dataset_folder_paths.dataset_id)))
  WHERE ((j.job_state_id = 4) AND (ds.dataset_rating_id > 1));


ALTER TABLE public.v_pde_all_completed_analysis_jobs_ext OWNER TO d3l243;

--
-- Name: TABLE v_pde_all_completed_analysis_jobs_ext; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_pde_all_completed_analysis_jobs_ext TO readaccess;

