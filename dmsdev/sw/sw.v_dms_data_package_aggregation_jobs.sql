--
-- Name: v_dms_data_package_aggregation_jobs; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_dms_data_package_aggregation_jobs AS
 SELECT src.data_pkg_id,
    src.job,
    src.tool,
    src.dataset,
    src.archive_storage_path,
    src.server_storage_path,
    src.dataset_folder,
    src.results_folder,
    COALESCE(jsh.step, 1) AS step,
    COALESCE(jsh.output_folder_name, ''::public.citext) AS shared_results_folder,
    src.dataset_id,
    src.organism,
    src.instrument_name,
    src.instrument_group,
    src.instrument_class,
    src.completed,
    src.parameter_file_name,
    src.settings_file_name,
    src.organism_db_name,
    src.protein_collection_list,
    src.protein_options,
    src.result_type,
    src.dataset_created,
    COALESCE(src.package_comment, ''::public.citext) AS package_comment,
    src.raw_data_type,
    src.experiment,
    src.experiment_reason,
    src.experiment_comment,
    src.experiment_newt_id,
    src.experiment_newt_name,
    src.data_pkg_id AS data_package_id
   FROM (dpkg.v_dms_data_package_aggregation_jobs src
     LEFT JOIN sw.t_job_steps_history jsh ON (((src.job = jsh.job) AND (jsh.most_recent_entry = 1) AND (jsh.shared_result_version > 0) AND (jsh.state = ANY (ARRAY[3, 5])))));


ALTER VIEW sw.v_dms_data_package_aggregation_jobs OWNER TO d3l243;

--
-- Name: VIEW v_dms_data_package_aggregation_jobs; Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON VIEW sw.v_dms_data_package_aggregation_jobs IS 'This view is used by function LoadDataPackageJobInfo in the DMS Analysis Manager';

--
-- Name: TABLE v_dms_data_package_aggregation_jobs; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_dms_data_package_aggregation_jobs TO readaccess;
GRANT SELECT ON TABLE sw.v_dms_data_package_aggregation_jobs TO writeaccess;

