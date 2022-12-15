--
-- Name: v_osm_package_picklist; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_osm_package_picklist AS
 SELECT (((t_osm_package.osm_pkg_id)::text || chr(32)) || (t_osm_package.osm_package_name)::text) AS label,
    t_osm_package.osm_pkg_id AS value
   FROM dpkg.t_osm_package;


ALTER TABLE dpkg.v_osm_package_picklist OWNER TO d3l243;

--
-- Name: VIEW v_osm_package_picklist; Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON VIEW dpkg.v_osm_package_picklist IS 'Used by ad-hoc query "osm_package_list"; see https://dmsdev.pnl.gov/config_db/edit_table/ad_hoc_query.db/utility_queries';

--
-- Name: TABLE v_osm_package_picklist; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_osm_package_picklist TO readaccess;
GRANT SELECT ON TABLE dpkg.v_osm_package_picklist TO writeaccess;

