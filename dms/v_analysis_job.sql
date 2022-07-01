--
-- Name: v_analysis_job; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job AS
 SELECT aj.job,
    antool.analysis_tool AS tool,
    ds.dataset,
    dfp.dataset_folder_path AS dataset_storage_path,
    (((dfp.dataset_folder_path)::text || '\'::text) || (aj.results_folder_name)::text) AS results_folder_path,
    aj.param_file_name,
    aj.settings_file_name,
    antool.param_file_storage_path,
    aj.organism_db_name AS organism_dbname,
    aj.protein_collection_list,
    aj.protein_options_list AS protein_options,
    o.organism_db_path AS organism_dbstorage_path,
    aj.job_state_id AS state_id,
    aj.priority,
    aj.comment,
    ds.ds_comp_state AS comp_state,
    instname.instrument_class AS inst_class,
    aj.dataset_id,
    aj.request_id,
    dfp.archive_folder_path,
    dfp.myemsl_path_flag,
    dfp.instrument_data_purged,
    e.experiment,
    c.campaign,
    instname.instrument,
    aj.state_name_cached AS state,
    ds.dataset_rating_id AS rating,
    aj.created,
    aj.start AS started,
    aj.finish AS finished,
    (aj.processing_time_minutes)::numeric(9,2) AS runtime,
    aj.special_processing,
    aj.batch_id
   FROM (((((((public.t_analysis_job aj
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
     JOIN public.t_organisms o ON ((aj.organism_id = o.organism_id)))
     JOIN public.t_analysis_tool antool ON ((aj.analysis_tool_id = antool.analysis_tool_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.v_dataset_folder_paths dfp ON ((ds.dataset_id = dfp.dataset_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)));


ALTER TABLE public.v_analysis_job OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job TO readaccess;

