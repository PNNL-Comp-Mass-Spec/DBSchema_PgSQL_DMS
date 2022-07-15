--
-- Name: v_get_pipeline_job_parameters; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_get_pipeline_job_parameters AS
 SELECT j.job,
    ds.dataset,
    ds.folder_name AS dataset_folder_name,
    COALESCE(archpath.network_share_path, ''::public.citext) AS archive_folder_path,
    j.param_file_name,
    j.settings_file_name,
    tool.param_file_storage_path,
    j.organism_db_name,
    j.protein_collection_list,
    j.protein_options_list,
    instname.instrument_class,
    instname.instrument_group,
    instname.instrument,
    instclass.raw_data_type,
    tool.search_engine_input_file_formats,
    org.organism,
    tool.org_db_required,
    tool.analysis_tool AS tool_name,
    tool.result_type,
    ds.dataset_id,
    ((sp.vol_name_client)::text || (sp.storage_path)::text) AS dataset_storage_path,
    ((sp.vol_name_client)::text || (( SELECT t_misc_paths.client
           FROM public.t_misc_paths
          WHERE (t_misc_paths.path_function = 'AnalysisXfer'::bpchar)))::text) AS transfer_folder_path,
    j.results_folder_name,
    j.special_processing,
    dtn.dataset_type AS datasettype,
    e.experiment,
    COALESCE(dsarch.instrument_data_purged, (0)::smallint) AS instrumentdatapurged
   FROM ((((((((((public.t_analysis_job j
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_organisms org ON ((j.organism_id = org.organism_id)))
     JOIN public.t_storage_path sp ON ((ds.storage_path_id = sp.storage_path_id)))
     JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_instrument_class instclass ON ((instname.instrument_class OPERATOR(public.=) instclass.instrument_class)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     LEFT JOIN public.t_dataset_archive dsarch ON ((ds.dataset_id = dsarch.dataset_id)))
     LEFT JOIN public.t_archive_path archpath ON ((dsarch.storage_path_id = archpath.archive_path_id)));


ALTER TABLE public.v_get_pipeline_job_parameters OWNER TO d3l243;

--
-- Name: TABLE v_get_pipeline_job_parameters; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_get_pipeline_job_parameters TO readaccess;

