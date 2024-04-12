--
-- Name: v_analysis_request_jobs_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_request_jobs_list_report AS
 SELECT j.job,
    j.priority,
    js.job_state AS state,
    tool.analysis_tool AS tool_name,
    ds.dataset,
    j.param_file_name AS param_file,
    j.settings_file_name AS settings_file,
    org.organism,
    j.organism_db_name AS organism_db,
    j.protein_collection_list,
    j.protein_options_list AS protein_options,
    j.comment,
    j.created,
    j.start AS started,
    j.finish AS finished,
    (j.progress)::numeric(9,2) AS job_progress,
    (j.eta_minutes)::numeric(18,1) AS job_eta_minutes,
    j.batch_id AS batch,
    j.request_id,
    (((dfp.dataset_folder_path)::text || ('\'::public.citext)::text) || (j.results_folder_name)::text) AS results_folder,
    (j.processing_time_minutes)::numeric(9,2) AS runtime_minutes,
    ds.dataset_id
   FROM (((((public.t_analysis_job j
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_organisms org ON ((j.organism_id = org.organism_id)))
     JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id)))
     JOIN public.t_analysis_job_state js ON ((j.job_state_id = js.job_state_id)))
     LEFT JOIN public.v_dataset_folder_paths dfp ON ((j.dataset_id = dfp.dataset_id)));


ALTER VIEW public.v_analysis_request_jobs_list_report OWNER TO d3l243;

--
-- Name: TABLE v_analysis_request_jobs_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_request_jobs_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_request_jobs_list_report TO writeaccess;

