--
-- Name: t_osm_package_storage; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_osm_package_storage (
    path_id integer NOT NULL,
    path_local_root public.citext,
    path_shared_root public.citext NOT NULL,
    path_web_root public.citext,
    state public.citext DEFAULT 'Active'::public.citext NOT NULL
);


ALTER TABLE dpkg.t_osm_package_storage OWNER TO d3l243;

--
-- Name: t_osm_package_storage_path_id_seq; Type: SEQUENCE; Schema: dpkg; Owner: d3l243
--

ALTER TABLE dpkg.t_osm_package_storage ALTER COLUMN path_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME dpkg.t_osm_package_storage_path_id_seq
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_osm_package_storage pk_t_osm_package_storage; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_osm_package_storage
    ADD CONSTRAINT pk_t_osm_package_storage PRIMARY KEY (path_id);

--
-- Name: TABLE t_osm_package_storage; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_osm_package_storage TO readaccess;
GRANT SELECT ON TABLE dpkg.t_osm_package_storage TO writeaccess;

