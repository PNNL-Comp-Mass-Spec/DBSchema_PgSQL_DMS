--
-- Name: v_data_package_paths; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_paths AS
 SELECT dp.data_pkg_id,
    dp.package_folder AS package_file_folder,
    (((((dp.path_team)::text || '\'::text) || (dp.path_year)::text) || '\'::text) || (dp.package_folder)::text) AS storage_path_relative,
    ((((((dps.path_shared_root)::text || (dp.path_team)::text) || '\'::text) || (dp.path_year)::text) || '\'::text) || (dp.package_folder)::text) AS share_path,
    ((((((dps.path_web_root)::text || (dp.path_team)::text) || '/'::text) || (dp.path_year)::text) || '/'::text) || (dp.package_folder)::text) AS web_path,
    ((((((dps.path_archive_root)::text || (dp.path_team)::text) || '/'::text) || (dp.path_year)::text) || '/'::text) || (dp.package_folder)::text) AS archive_path,
    ((((public.combine_paths((dps.path_local_root)::text, (dp.path_team)::text) || '\'::text) || (dp.path_year)::text) || '\'::text) || (dp.package_folder)::text) AS local_path
   FROM (dpkg.t_data_package dp
     JOIN dpkg.t_data_package_storage dps ON ((dp.storage_path_id = dps.path_id)));


ALTER VIEW dpkg.v_data_package_paths OWNER TO d3l243;

--
-- Name: TABLE v_data_package_paths; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_paths TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_paths TO writeaccess;

