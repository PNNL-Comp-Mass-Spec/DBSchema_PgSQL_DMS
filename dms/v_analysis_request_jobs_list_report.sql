--
-- Name: v_analysis_request_jobs_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_request_jobs_list_report AS
 SELECT aj.job,
    aj.priority AS pri,
    asn.job_state AS state,
    tool.analysis_tool AS tool_name,
    ds.dataset,
    aj.param_file_name AS parm_file,
    aj.settings_file_name AS settings_file,
    org.organism,
    aj.organism_db_name AS organism_db,
    aj.protein_collection_list,
    aj.protein_options_list AS protein_options,
    aj.comment,
    aj.created,
    aj.start AS started,
    aj.finish AS finished,
    (aj.progress)::numeric(9,2) AS job_progress,
    (aj.eta_minutes)::numeric(18,1) AS job_eta_minutes,
    aj.batch_id AS batch,
    aj.request_id,
    (((dfp.dataset_folder_path)::text || '\'::text) || (aj.results_folder_name)::text) AS results_folder,
    (aj.processing_time_minutes)::numeric(9,2) AS runtime,
    ds.dataset_id
   FROM (((((public.t_analysis_job aj
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
     JOIN public.t_organisms org ON ((aj.organism_id = org.organism_id)))
     JOIN public.t_analysis_tool tool ON ((aj.analysis_tool_id = tool.analysis_tool_id)))
     JOIN public.t_analysis_job_state asn ON ((aj.job_state_id = asn.job_state_id)))
     LEFT JOIN public.v_dataset_folder_paths dfp ON ((aj.dataset_id = dfp.dataset_id)));


ALTER TABLE public.v_analysis_request_jobs_list_report OWNER TO d3l243;

--
-- Name: TABLE v_analysis_request_jobs_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_request_jobs_list_report TO readaccess;

