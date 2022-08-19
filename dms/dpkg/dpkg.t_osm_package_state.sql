--
-- Name: t_osm_package_state; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_osm_package_state (
    state_name public.citext NOT NULL,
    description public.citext
);


ALTER TABLE dpkg.t_osm_package_state OWNER TO d3l243;

--
-- Name: t_osm_package_state pk_t_osm_package_state; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_osm_package_state
    ADD CONSTRAINT pk_t_osm_package_state PRIMARY KEY (state_name);

--
-- Name: TABLE t_osm_package_state; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_osm_package_state TO readaccess;

