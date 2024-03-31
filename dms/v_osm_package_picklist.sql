--
-- Name: v_osm_package_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_osm_package_picklist AS
 SELECT osm_pkg_id AS id,
    osm_package_name AS name,
    (((((((osm_pkg_id)::public.citext)::text || (': '::public.citext)::text))::public.citext)::text || (osm_package_name)::text))::public.citext AS id_with_name
   FROM dpkg.t_osm_package;


ALTER VIEW public.v_osm_package_picklist OWNER TO d3l243;

--
-- Name: TABLE v_osm_package_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_osm_package_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_osm_package_picklist TO writeaccess;

