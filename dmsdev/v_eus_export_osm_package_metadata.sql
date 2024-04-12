--
-- Name: v_eus_export_osm_package_metadata; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_export_osm_package_metadata AS
 SELECT osmpkg.osm_pkg_id AS id,
    osmpkg.osm_package_name AS name,
    osmpkg.package_type AS type,
    osmpkg.description,
    osmpkg.keywords,
    osmpkg.comment,
    u.name AS owner,
    COALESCE(osmpkg.owner_username, ''::public.citext) AS owner_username,
    osmpkg.created,
    osmpkg.last_modified AS modified,
    osmpkg.state,
    ('/aurora/dmsarch/dms_attachments/osm_package/spread/'::text || (osmpkg.osm_pkg_id)::text) AS archive_path
   FROM (dpkg.t_osm_package osmpkg
     LEFT JOIN public.t_users u ON ((u.username OPERATOR(public.=) osmpkg.owner_username)));


ALTER VIEW public.v_eus_export_osm_package_metadata OWNER TO d3l243;

--
-- Name: TABLE v_eus_export_osm_package_metadata; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_export_osm_package_metadata TO readaccess;
GRANT SELECT ON TABLE public.v_eus_export_osm_package_metadata TO writeaccess;

