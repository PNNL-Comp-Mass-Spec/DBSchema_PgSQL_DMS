--
-- Name: v_dms_data_package_datasets; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_dms_data_package_datasets AS
 SELECT v_dms_data_package_aggregation_datasets.data_package_id,
    v_dms_data_package_aggregation_datasets.dataset_id,
    v_dms_data_package_aggregation_datasets.dataset,
    v_dms_data_package_aggregation_datasets.dataset_folder_path,
    v_dms_data_package_aggregation_datasets.archive_folder_path,
    v_dms_data_package_aggregation_datasets.instrument_name,
    v_dms_data_package_aggregation_datasets.instrument_group,
    v_dms_data_package_aggregation_datasets.instrument_class,
    v_dms_data_package_aggregation_datasets.raw_data_type,
    v_dms_data_package_aggregation_datasets.acq_time_start,
    v_dms_data_package_aggregation_datasets.dataset_created,
    v_dms_data_package_aggregation_datasets.organism,
    v_dms_data_package_aggregation_datasets.experiment_newt_id,
    v_dms_data_package_aggregation_datasets.experiment_newt_name,
    v_dms_data_package_aggregation_datasets.experiment,
    v_dms_data_package_aggregation_datasets.experiment_reason,
    v_dms_data_package_aggregation_datasets.experiment_comment,
    v_dms_data_package_aggregation_datasets.experiment_tissue_id,
    v_dms_data_package_aggregation_datasets.experiment_tissue_name,
    COALESCE(v_dms_data_package_aggregation_datasets.package_comment, ''::public.citext) AS package_comment
   FROM dpkg.v_dms_data_package_aggregation_datasets;


ALTER TABLE sw.v_dms_data_package_datasets OWNER TO d3l243;

--
-- Name: VIEW v_dms_data_package_datasets; Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON VIEW sw.v_dms_data_package_datasets IS 'This view is used by function LoadDataPackageDatasetInfo in the DMS Analysis Manager';

--
-- Name: TABLE v_dms_data_package_datasets; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_dms_data_package_datasets TO readaccess;
GRANT SELECT ON TABLE sw.v_dms_data_package_datasets TO writeaccess;

