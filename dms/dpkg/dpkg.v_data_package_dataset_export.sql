--
-- Name: v_data_package_dataset_export; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_dataset_export AS
 SELECT t_data_package_datasets.data_pkg_id AS data_package_id,
    t_data_package_datasets.dataset_id,
    t_data_package_datasets.dataset,
    t_data_package_datasets.experiment,
    t_data_package_datasets.instrument,
    t_data_package_datasets.created,
    t_data_package_datasets.item_added,
    t_data_package_datasets.package_comment
   FROM dpkg.t_data_package_datasets;


ALTER TABLE dpkg.v_data_package_dataset_export OWNER TO d3l243;

--
-- Name: TABLE v_data_package_dataset_export; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_dataset_export TO readaccess;

