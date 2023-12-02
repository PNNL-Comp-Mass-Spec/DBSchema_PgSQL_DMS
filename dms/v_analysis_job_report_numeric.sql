--
-- Name: v_analysis_job_report_numeric; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_report_numeric AS
 SELECT j.job,
    j.priority,
    j.state_name_cached AS state,
    tool.analysis_tool AS tool_name,
    ds.dataset,
    instname.instrument,
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
    round((j.processing_time_minutes)::numeric, 2) AS runtime_minutes,
    COALESCE(j.assigned_processor_name, '(none)'::public.citext) AS cpu,
    COALESCE(j.results_folder_name, '(none)'::public.citext) AS results_folder,
    j.batch_id AS batch,
    j.request_id AS request,
    spath.machine_name AS storage_server,
    dsr.dataset_rating
   FROM (public.t_dataset_rating_name dsr
     JOIN (((((public.t_analysis_job j
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_organisms org ON ((j.organism_id = org.organism_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id))) ON ((dsr.dataset_rating_id = ds.dataset_rating_id)));


ALTER VIEW public.v_analysis_job_report_numeric OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_report_numeric; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_report_numeric TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_report_numeric TO writeaccess;

