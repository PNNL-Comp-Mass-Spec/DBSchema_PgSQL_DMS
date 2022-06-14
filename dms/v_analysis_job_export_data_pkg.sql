--
-- Name: v_analysis_job_export_data_pkg; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_export_data_pkg AS
 SELECT aj.job,
    analysistool.analysis_tool AS tool,
    ds.dataset,
    ((dsarch.archive_path)::text || '\'::text) AS archivestoragepath,
    public.combine_paths((sp.vol_name_client)::text, (sp.storage_path)::text) AS serverstoragepath,
    ds.folder_name AS datasetfolder,
    aj.results_folder_name AS resultsfolder,
    aj.dataset_id AS datasetid,
    org.name AS organism,
    instname.instrument AS instrumentname,
    instname.instrument_group AS instrumentgroup,
    instname.instrument_class AS instrumentclass,
    aj.finish AS completed,
    aj.param_file_name AS parameterfilename,
    aj.settings_file_name AS settingsfilename,
    aj.organism_db_name AS organismdbname,
    aj.protein_collection_list AS proteincollectionlist,
    aj.protein_options_list AS proteinoptions,
    analysistool.result_type AS resulttype,
    ds.created AS ds_created,
    instclass.raw_data_type AS rawdatatype,
    e.experiment,
    e.reason AS experiment_reason,
    e.comment AS experiment_comment,
    org.newt_id AS experiment_newt_id,
    org.newt_name AS experiment_newt_name
   FROM ((((((((public.t_analysis_job aj
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_instrument_class instclass ON ((instname.instrument_class OPERATOR(public.=) instclass.instrument_class)))
     JOIN public.t_storage_path sp ON ((ds.storage_path_id = sp.storage_path_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_analysis_tool analysistool ON ((aj.analysis_tool_id = analysistool.analysis_tool_id)))
     JOIN public.v_organism_export org ON ((e.organism_id = org.organism_id)))
     JOIN public.v_dataset_archive_path dsarch ON ((ds.dataset_id = dsarch.dataset_id)));


ALTER TABLE public.v_analysis_job_export_data_pkg OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_export_data_pkg; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_export_data_pkg TO readaccess;

