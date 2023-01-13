--
-- Name: v_analysis_job; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job AS
 SELECT j.job,
    tool.analysis_tool AS tool,
    ds.dataset,
    dfp.dataset_folder_path AS dataset_storage_path,
    (((dfp.dataset_folder_path)::text || '\'::text) || (j.results_folder_name)::text) AS results_folder_path,
    j.param_file_name,
    j.settings_file_name,
    tool.param_file_storage_path,
    j.organism_db_name,
    j.protein_collection_list,
    j.protein_options_list AS protein_options,
    o.organism_db_path AS organism_dbstorage_path,
    j.job_state_id AS state_id,
    j.priority,
    j.comment,
    instname.instrument_class AS inst_class,
    j.dataset_id,
    j.request_id,
    dfp.archive_folder_path,
    dfp.myemsl_path_flag,
    dfp.instrument_data_purged,
    e.experiment,
    c.campaign,
    instname.instrument,
    j.state_name_cached AS state,
    ds.dataset_rating_id AS rating,
    j.created,
    j.start AS started,
    j.finish AS finished,
    round((j.processing_time_minutes)::numeric, 2) AS runtime,
    j.special_processing,
    j.batch_id
   FROM (((((((public.t_analysis_job j
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_organisms o ON ((j.organism_id = o.organism_id)))
     JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.v_dataset_folder_paths dfp ON ((ds.dataset_id = dfp.dataset_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)));


ALTER TABLE public.v_analysis_job OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job TO writeaccess;

