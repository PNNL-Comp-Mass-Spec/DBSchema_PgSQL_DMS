--
-- Name: t_osm_package_type; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_osm_package_type (
    package_type public.citext NOT NULL,
    description public.citext
);


ALTER TABLE dpkg.t_osm_package_type OWNER TO d3l243;

--
-- Name: t_osm_package_type pk_t_osm_package_type; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_osm_package_type
    ADD CONSTRAINT pk_t_osm_package_type PRIMARY KEY (package_type);

ALTER TABLE dpkg.t_osm_package_type CLUSTER ON pk_t_osm_package_type;

--
-- Name: TABLE t_osm_package_type; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_osm_package_type TO readaccess;
GRANT SELECT ON TABLE dpkg.t_osm_package_type TO writeaccess;

