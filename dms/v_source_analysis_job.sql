--
-- Name: v_source_analysis_job; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_source_analysis_job AS
 SELECT aj.job,
    aj.state_name_cached AS state,
    analysistool.analysis_tool AS tool,
    ds.dataset,
    e.experiment,
    instname.instrument,
    aj.param_file_name AS param_file,
    aj.settings_file_name AS settings_file,
    aj.comment,
    aj.request_id AS job_request,
    COALESCE(aj.results_folder_name, '(none)'::public.citext) AS results_folder,
    instclass.raw_data_type,
    ((spath.vol_name_client)::text || 'DMS3_XFER\'::text) AS transfer_folder_path,
    archpath.network_share_path AS archive_folder_path,
    ((sp.vol_name_client)::text || (sp.storage_path)::text) AS dataset_storage_path,
    dsarch.instrument_data_purged
   FROM (((((((((public.t_analysis_job aj
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
     JOIN public.t_analysis_tool analysistool ON ((aj.analysis_tool_id = analysistool.analysis_tool_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_instrument_class instclass ON ((instclass.instrument_class OPERATOR(public.=) instname.instrument_class)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_dataset_archive dsarch ON ((ds.dataset_id = dsarch.dataset_id)))
     JOIN public.t_archive_path archpath ON ((dsarch.storage_path_id = archpath.archive_path_id)))
     JOIN public.t_storage_path sp ON ((ds.storage_path_id = sp.storage_path_id)));


ALTER TABLE public.v_source_analysis_job OWNER TO d3l243;

--
-- Name: TABLE v_source_analysis_job; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_source_analysis_job TO readaccess;

