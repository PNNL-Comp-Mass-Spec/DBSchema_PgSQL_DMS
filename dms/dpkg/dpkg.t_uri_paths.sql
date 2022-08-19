--
-- Name: t_uri_paths; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_uri_paths (
    uri_path_id integer NOT NULL,
    uri_path public.citext NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE dpkg.t_uri_paths OWNER TO d3l243;

--
-- Name: t_uri_paths_uri_path_id_seq; Type: SEQUENCE; Schema: dpkg; Owner: d3l243
--

ALTER TABLE dpkg.t_uri_paths ALTER COLUMN uri_path_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME dpkg.t_uri_paths_uri_path_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_uri_paths pk_t_uri_paths; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_uri_paths
    ADD CONSTRAINT pk_t_uri_paths PRIMARY KEY (uri_path_id);

--
-- Name: TABLE t_uri_paths; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_uri_paths TO readaccess;

