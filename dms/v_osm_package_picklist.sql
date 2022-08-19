--
-- Name: v_osm_package_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_osm_package_picklist AS
 SELECT t_osm_package.osm_pkg_id AS id,
    t_osm_package.osm_package_name AS name,
    (((t_osm_package.osm_pkg_id)::text || ': '::text) || (t_osm_package.osm_package_name)::text) AS id_with_name
   FROM dpkg.t_osm_package;


ALTER TABLE public.v_osm_package_picklist OWNER TO d3l243;

--
-- Name: TABLE v_osm_package_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_osm_package_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_osm_package_picklist TO writeaccess;

