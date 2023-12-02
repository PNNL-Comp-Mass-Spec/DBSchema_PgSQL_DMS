--
-- Name: v_osm_package_paths; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_osm_package_paths AS
 SELECT osmpackage.osm_pkg_id AS id,
    pkgstorage.path_id,
    pkgstorage.path_shared_root,
    (((EXTRACT(year FROM osmpackage.created))::text || '\'::text) || (osmpackage.osm_pkg_id)::text) AS path_folder,
    ((((pkgstorage.path_shared_root)::text || (EXTRACT(year FROM osmpackage.created))::text) || '\'::text) || (osmpackage.osm_pkg_id)::text) AS share_path
   FROM (dpkg.t_osm_package osmpackage
     JOIN dpkg.t_osm_package_storage pkgstorage ON ((osmpackage.path_root = pkgstorage.path_id)));


ALTER VIEW dpkg.v_osm_package_paths OWNER TO d3l243;

--
-- Name: TABLE v_osm_package_paths; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_osm_package_paths TO readaccess;
GRANT SELECT ON TABLE dpkg.v_osm_package_paths TO writeaccess;

