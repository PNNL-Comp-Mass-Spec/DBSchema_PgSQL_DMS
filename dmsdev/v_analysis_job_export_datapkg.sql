--
-- Name: v_analysis_job_export_datapkg; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_export_datapkg AS
 SELECT aj.job,
    analysistool.analysis_tool AS tool,
    ds.dataset,
    ((dsarch.archive_path)::text || '\'::text) AS archive_storage_path,
    public.combine_paths((spath.vol_name_client)::text, (spath.storage_path)::text) AS server_storage_path,
    ds.folder_name AS dataset_folder,
    aj.results_folder_name AS results_folder,
    aj.dataset_id,
    org.name AS organism,
    instname.instrument AS instrument_name,
    instname.instrument_group,
    instname.instrument_class,
    aj.finish AS completed,
    aj.param_file_name AS parameter_file_name,
    aj.settings_file_name,
    aj.organism_db_name,
    aj.protein_collection_list,
    aj.protein_options_list AS protein_options,
    analysistool.result_type,
    ds.created AS dataset_created,
    instclass.raw_data_type,
    e.experiment,
    e.reason AS experiment_reason,
    e.comment AS experiment_comment,
    org.newt_id AS experiment_newt_id,
    org.newt_name AS experiment_newt_name
   FROM ((((((((public.t_analysis_job aj
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_instrument_class instclass ON ((instname.instrument_class OPERATOR(public.=) instclass.instrument_class)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_analysis_tool analysistool ON ((aj.analysis_tool_id = analysistool.analysis_tool_id)))
     JOIN public.v_organism_export org ON ((e.organism_id = org.organism_id)))
     JOIN public.v_dataset_archive_path dsarch ON ((ds.dataset_id = dsarch.dataset_id)));


ALTER VIEW public.v_analysis_job_export_datapkg OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_export_datapkg; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_export_datapkg TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_export_datapkg TO writeaccess;

