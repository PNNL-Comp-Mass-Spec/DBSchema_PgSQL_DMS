--
-- Name: v_dms_data_package_datasets; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_dms_data_package_datasets AS
 SELECT data_pkg_id,
    dataset_id,
    dataset,
    dataset_folder_path,
    archive_folder_path,
    instrument_name,
    instrument_group,
    instrument_class,
    raw_data_type,
    acq_time_start,
    dataset_created,
    organism,
    experiment_newt_id,
    experiment_newt_name,
    experiment,
    experiment_reason,
    experiment_comment,
    experiment_tissue_id,
    experiment_tissue_name,
    COALESCE(package_comment, ''::public.citext) AS package_comment,
    data_pkg_id AS data_package_id
   FROM dpkg.v_dms_data_package_aggregation_datasets dpd;


ALTER VIEW sw.v_dms_data_package_datasets OWNER TO d3l243;

--
-- Name: VIEW v_dms_data_package_datasets; Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON VIEW sw.v_dms_data_package_datasets IS 'This view is used by function LoadDataPackageDatasetInfo in the DMS Analysis Manager';

--
-- Name: TABLE v_dms_data_package_datasets; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_dms_data_package_datasets TO readaccess;
GRANT SELECT ON TABLE sw.v_dms_data_package_datasets TO writeaccess;

