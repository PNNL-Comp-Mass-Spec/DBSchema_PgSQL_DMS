--
-- Name: v_dms_data_package_aggregation_jobs; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_dms_data_package_aggregation_jobs AS
 SELECT tpj.data_pkg_id AS data_package_id,
    aj.job,
    analysistool.analysis_tool AS tool,
    ds.dataset,
    ((dsarch.archive_path)::text || '\'::text) AS archive_storage_path,
    public.combine_paths((sp.vol_name_client)::text, (sp.storage_path)::text) AS server_storage_path,
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
    tpj.package_comment,
    instclass.raw_data_type,
    e.experiment,
    e.reason AS experiment_reason,
    e.comment AS experiment_comment,
    org.newt_id AS experiment_newt_id,
    org.newt_name AS experiment_newt_name
   FROM (((((((((dpkg.t_data_package_analysis_jobs tpj
     JOIN public.t_analysis_job aj ON ((tpj.job = aj.job)))
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_instrument_class instclass ON ((instname.instrument_class OPERATOR(public.=) instclass.instrument_class)))
     JOIN public.t_storage_path sp ON ((ds.storage_path_id = sp.storage_path_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_analysis_tool analysistool ON ((aj.analysis_tool_id = analysistool.analysis_tool_id)))
     JOIN public.v_organism_export org ON ((e.organism_id = org.organism_id)))
     JOIN public.v_dataset_archive_path dsarch ON ((ds.dataset_id = dsarch.dataset_id)));


ALTER TABLE dpkg.v_dms_data_package_aggregation_jobs OWNER TO d3l243;

--
-- Name: VIEW v_dms_data_package_aggregation_jobs; Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON VIEW dpkg.v_dms_data_package_aggregation_jobs IS 'Note that this view is used by V_DMS_Data_Package_Aggregation_Jobs in the sw schema, and the DMS Analysis Manager uses that view to retrieve metadata for data package jobs';

--
-- Name: TABLE v_dms_data_package_aggregation_jobs; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_dms_data_package_aggregation_jobs TO readaccess;
GRANT SELECT ON TABLE dpkg.v_dms_data_package_aggregation_jobs TO writeaccess;

