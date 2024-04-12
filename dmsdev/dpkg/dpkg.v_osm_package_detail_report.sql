--
-- Name: v_osm_package_detail_report; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_osm_package_detail_report AS
 SELECT osmpackage.osm_pkg_id AS id,
    osmpackage.osm_package_name AS name,
    osmpackage.package_type,
    osmpackage.description,
    osmpackage.keywords,
    COALESCE(u.name, osmpackage.owner_username) AS owner,
    osmpackage.created,
    osmpackage.last_modified,
    osmpackage.sample_prep_requests,
    osmpackage.state,
    osmpackage.wiki_page_link,
    osmpackage.user_folder_path AS user_folder,
    packagepaths.share_path AS managed_folder
   FROM ((dpkg.t_osm_package osmpackage
     LEFT JOIN public.t_users u ON ((osmpackage.owner_username OPERATOR(public.=) u.username)))
     LEFT JOIN dpkg.v_osm_package_paths packagepaths ON ((osmpackage.osm_pkg_id = packagepaths.id)));


ALTER VIEW dpkg.v_osm_package_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_osm_package_detail_report; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_osm_package_detail_report TO readaccess;
GRANT SELECT ON TABLE dpkg.v_osm_package_detail_report TO writeaccess;

