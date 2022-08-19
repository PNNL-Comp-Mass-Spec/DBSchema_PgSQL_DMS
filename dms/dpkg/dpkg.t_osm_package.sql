--
-- Name: t_osm_package; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_osm_package (
    osm_pkg_id integer NOT NULL,
    osm_package_name public.citext NOT NULL,
    package_type public.citext DEFAULT 'General'::public.citext NOT NULL,
    description public.citext DEFAULT ''::public.citext,
    keywords public.citext,
    comment public.citext DEFAULT ''::public.citext,
    owner public.citext,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_modified timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    state public.citext DEFAULT 'Active'::public.citext NOT NULL,
    wiki_page_link public.citext,
    sample_prep_requests public.citext,
    path_root integer,
    user_folder_path public.citext
);


ALTER TABLE dpkg.t_osm_package OWNER TO d3l243;

--
-- Name: t_osm_package_osm_pkg_id_seq; Type: SEQUENCE; Schema: dpkg; Owner: d3l243
--

ALTER TABLE dpkg.t_osm_package ALTER COLUMN osm_pkg_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME dpkg.t_osm_package_osm_pkg_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_osm_package pk_t_osm_package; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_osm_package
    ADD CONSTRAINT pk_t_osm_package PRIMARY KEY (osm_pkg_id);

--
-- Name: t_osm_package fk_t_osm_package_t_osm_package_state; Type: FK CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_osm_package
    ADD CONSTRAINT fk_t_osm_package_t_osm_package_state FOREIGN KEY (state) REFERENCES dpkg.t_osm_package_state(state_name);

--
-- Name: t_osm_package fk_t_osm_package_t_osm_package_storage; Type: FK CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_osm_package
    ADD CONSTRAINT fk_t_osm_package_t_osm_package_storage FOREIGN KEY (path_root) REFERENCES dpkg.t_osm_package_storage(path_id);

--
-- Name: t_osm_package fk_t_osm_package_t_osm_package_type; Type: FK CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_osm_package
    ADD CONSTRAINT fk_t_osm_package_t_osm_package_type FOREIGN KEY (package_type) REFERENCES dpkg.t_osm_package_type(package_type);

--
-- Name: TABLE t_osm_package; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_osm_package TO readaccess;
GRANT SELECT ON TABLE dpkg.t_osm_package TO writeaccess;

