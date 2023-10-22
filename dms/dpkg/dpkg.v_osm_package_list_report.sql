--
-- Name: v_osm_package_list_report; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_osm_package_list_report AS
 SELECT o.osm_pkg_id AS id,
    o.osm_package_name AS name,
    o.package_type AS type,
    o.description,
    o.keywords,
    o.comment,
    (((((((u.name)::text || (' ('::public.citext)::text))::public.citext)::text || (COALESCE(o.owner_username, ''::public.citext))::text) || (')'::public.citext)::text))::public.citext AS owner,
    o.created,
    o.state,
    o.last_modified AS modified,
    o.sample_prep_requests AS sample_prep
   FROM (dpkg.t_osm_package o
     LEFT JOIN public.t_users u ON ((u.username OPERATOR(public.=) o.owner_username)));


ALTER TABLE dpkg.v_osm_package_list_report OWNER TO d3l243;

--
-- Name: TABLE v_osm_package_list_report; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_osm_package_list_report TO readaccess;
GRANT SELECT ON TABLE dpkg.v_osm_package_list_report TO writeaccess;

