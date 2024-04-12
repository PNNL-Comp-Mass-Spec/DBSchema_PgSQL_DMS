--
-- Name: v_osm_package_entry; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_osm_package_entry AS
 SELECT osm_pkg_id AS id,
    osm_package_name AS name,
    package_type,
    description,
    keywords,
    comment,
    owner_username AS owner,
    state,
    sample_prep_requests AS sample_prep_request_list,
    user_folder_path
   FROM dpkg.t_osm_package;


ALTER VIEW dpkg.v_osm_package_entry OWNER TO d3l243;

--
-- Name: TABLE v_osm_package_entry; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_osm_package_entry TO readaccess;
GRANT SELECT ON TABLE dpkg.v_osm_package_entry TO writeaccess;

