--
-- Name: v_pde_xt_analysis_jobs_ext; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_pde_xt_analysis_jobs_ext AS
 SELECT t_analysis_job.job AS analysis_id,
    t_dataset.dataset AS dataset_name,
    t_experiments.experiment,
    t_campaign.campaign,
    t_analysis_job.finish AS completed,
    t_analysis_job.param_file_name AS param_file_used,
    t_organisms.organism,
    t_analysis_job.organism_db_name AS organism_database_used,
    t_analysis_job.protein_collection_list AS protein_collections_used,
    t_analysis_job.protein_options_list AS protein_collection_options,
    ((((v_dataset_folder_paths.dataset_folder_path)::text || '\'::text) || (t_analysis_job.results_folder_name)::text) || '\'::text) AS analysis_job_path,
    t_instrument_name.instrument AS instrument_name,
    t_analysis_job.request_id AS analysis_job_request_id,
    t_analysis_job_request.request_name AS analysis_job_request_name,
    ((((v_dataset_folder_paths.archive_folder_path)::text || '\'::text) || (t_analysis_job.results_folder_name)::text) || '\'::text) AS analysis_job_archive_path
   FROM (((((((((public.t_analysis_job
     JOIN public.t_dataset ON ((t_analysis_job.dataset_id = t_dataset.dataset_id)))
     JOIN public.t_instrument_name ON ((t_dataset.instrument_id = t_instrument_name.instrument_id)))
     JOIN public.t_storage_path ON ((t_dataset.storage_path_id = t_storage_path.storage_path_id)))
     JOIN public.t_experiments ON ((t_dataset.exp_id = t_experiments.exp_id)))
     JOIN public.t_analysis_tool ON ((t_analysis_job.analysis_tool_id = t_analysis_tool.analysis_tool_id)))
     JOIN public.t_campaign ON ((t_experiments.campaign_id = t_campaign.campaign_id)))
     JOIN public.t_analysis_job_request ON ((t_analysis_job.request_id = t_analysis_job_request.request_id)))
     JOIN public.t_organisms ON ((t_analysis_job.organism_id = t_organisms.organism_id)))
     JOIN public.v_dataset_folder_paths ON ((t_dataset.dataset_id = v_dataset_folder_paths.dataset_id)))
  WHERE ((t_analysis_job.job_state_id = 4) AND (t_analysis_tool.analysis_tool OPERATOR(public.~~) '%xtandem%'::public.citext) AND (t_dataset.dataset_rating_id > 1));


ALTER TABLE public.v_pde_xt_analysis_jobs_ext OWNER TO d3l243;

--
-- Name: TABLE v_pde_xt_analysis_jobs_ext; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_pde_xt_analysis_jobs_ext TO readaccess;

