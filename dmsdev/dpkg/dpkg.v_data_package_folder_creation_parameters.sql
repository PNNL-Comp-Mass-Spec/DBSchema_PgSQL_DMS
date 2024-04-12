--
-- Name: v_data_package_folder_creation_parameters; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_folder_creation_parameters AS
 SELECT dp.data_pkg_id AS id,
    dps.path_local_root AS local,
    dps.path_shared_root AS share,
    dp.path_year AS year,
    dp.path_team AS team,
    dp.package_folder AS folder
   FROM (dpkg.t_data_package dp
     JOIN dpkg.t_data_package_storage dps ON ((dp.storage_path_id = dps.path_id)));


ALTER VIEW dpkg.v_data_package_folder_creation_parameters OWNER TO d3l243;

--
-- Name: TABLE v_data_package_folder_creation_parameters; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_folder_creation_parameters TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_folder_creation_parameters TO writeaccess;

