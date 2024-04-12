--
-- Name: v_analysis_job_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_report AS
 SELECT j.job,
    j.priority AS pri,
    js.job_state AS state,
    tool.analysis_tool AS tool_name,
    t_dataset.dataset,
    j.param_file_name AS param_file,
    j.settings_file_name AS settings_file,
    t_organisms.organism,
    j.organism_db_name AS organism_db,
    j.protein_collection_list,
    j.protein_options_list AS protein_options,
    j.comment,
    j.created,
    j.start AS started,
    j.finish AS finished,
    COALESCE(j.assigned_processor_name, '(none)'::public.citext) AS cpu,
    COALESCE(j.results_folder_name, '(none)'::public.citext) AS results_folder,
    j.batch_id AS batch
   FROM (((((public.t_analysis_job j
     JOIN public.t_dataset ON ((j.dataset_id = t_dataset.dataset_id)))
     JOIN public.t_organisms ON ((j.organism_id = t_organisms.organism_id)))
     JOIN public.t_storage_path ON ((t_dataset.storage_path_id = t_storage_path.storage_path_id)))
     JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id)))
     JOIN public.t_analysis_job_state js ON ((j.job_state_id = js.job_state_id)));


ALTER VIEW public.v_analysis_job_report OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_report TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_report TO writeaccess;

