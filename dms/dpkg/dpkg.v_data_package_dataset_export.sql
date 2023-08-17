--
-- Name: v_data_package_dataset_export; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_dataset_export AS
 SELECT dpd.data_pkg_id,
    dpd.dataset_id,
    dpd.dataset,
    dpd.experiment,
    dpd.instrument,
    dpd.created,
    dpd.item_added,
    dpd.package_comment,
    dpd.data_pkg_id AS data_package_id
   FROM dpkg.t_data_package_datasets dpd;


ALTER TABLE dpkg.v_data_package_dataset_export OWNER TO d3l243;

--
-- Name: TABLE v_data_package_dataset_export; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_dataset_export TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_dataset_export TO writeaccess;

