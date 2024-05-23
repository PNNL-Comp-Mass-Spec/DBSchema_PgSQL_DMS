--
-- Name: v_osm_package_label_value_picklist; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_osm_package_label_value_picklist AS
 SELECT (((((((osm_pkg_id)::public.citext)::text || chr(32)))::public.citext)::text || (osm_package_name)::text))::public.citext AS label,
    osm_pkg_id AS value
   FROM dpkg.t_osm_package;


ALTER VIEW dpkg.v_osm_package_label_value_picklist OWNER TO d3l243;

--
-- Name: VIEW v_osm_package_label_value_picklist; Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON VIEW dpkg.v_osm_package_label_value_picklist IS 'Used by ad-hoc query "osm_package_list"; see https://dmsdev.pnl.gov/config_db/edit_table/ad_hoc_query.db/utility_queries';

--
-- Name: TABLE v_osm_package_label_value_picklist; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_osm_package_label_value_picklist TO readaccess;
GRANT SELECT ON TABLE dpkg.v_osm_package_label_value_picklist TO writeaccess;

