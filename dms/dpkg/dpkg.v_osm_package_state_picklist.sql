--
-- Name: v_osm_package_state_picklist; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_osm_package_state_picklist AS
 SELECT state_name AS name,
    description
   FROM dpkg.t_osm_package_state;


ALTER VIEW dpkg.v_osm_package_state_picklist OWNER TO d3l243;

--
-- Name: TABLE v_osm_package_state_picklist; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_osm_package_state_picklist TO readaccess;
GRANT SELECT ON TABLE dpkg.v_osm_package_state_picklist TO writeaccess;

