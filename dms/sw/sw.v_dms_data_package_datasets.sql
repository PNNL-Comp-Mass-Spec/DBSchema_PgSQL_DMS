--
-- Name: v_dms_data_package_datasets; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_dms_data_package_datasets AS
 SELECT dpd.data_pkg_id,
    dpd.dataset_id,
    dpd.dataset,
    dpd.dataset_folder_path,
    dpd.archive_folder_path,
    dpd.instrument_name,
    dpd.instrument_group,
    dpd.instrument_class,
    dpd.raw_data_type,
    dpd.acq_time_start,
    dpd.dataset_created,
    dpd.organism,
    dpd.experiment_newt_id,
    dpd.experiment_newt_name,
    dpd.experiment,
    dpd.experiment_reason,
    dpd.experiment_comment,
    dpd.experiment_tissue_id,
    dpd.experiment_tissue_name,
    COALESCE(dpd.package_comment, ''::public.citext) AS package_comment,
    dpd.data_pkg_id AS data_package_id
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

