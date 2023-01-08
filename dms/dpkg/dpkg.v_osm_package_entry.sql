--
-- Name: v_osm_package_entry; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_osm_package_entry AS
 SELECT t_osm_package.osm_pkg_id AS id,
    t_osm_package.osm_package_name AS name,
    t_osm_package.package_type,
    t_osm_package.description,
    t_osm_package.keywords,
    t_osm_package.comment,
    t_osm_package.owner,
    t_osm_package.state,
    t_osm_package.sample_prep_requests AS sample_prep_request_list,
    t_osm_package.user_folder_path
   FROM dpkg.t_osm_package;


ALTER TABLE dpkg.v_osm_package_entry OWNER TO d3l243;

--
-- Name: TABLE v_osm_package_entry; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_osm_package_entry TO readaccess;
GRANT SELECT ON TABLE dpkg.v_osm_package_entry TO writeaccess;

