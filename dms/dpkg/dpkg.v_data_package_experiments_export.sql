--
-- Name: v_data_package_experiments_export; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_experiments_export AS
 SELECT t_data_package_experiments.data_pkg_id AS data_package_id,
    t_data_package_experiments.experiment_id,
    t_data_package_experiments.experiment,
    t_data_package_experiments.created,
    t_data_package_experiments.item_added,
    t_data_package_experiments.package_comment
   FROM dpkg.t_data_package_experiments;


ALTER TABLE dpkg.v_data_package_experiments_export OWNER TO d3l243;

--
-- Name: TABLE v_data_package_experiments_export; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_experiments_export TO readaccess;

