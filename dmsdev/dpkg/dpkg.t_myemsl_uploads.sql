--
-- Name: t_myemsl_uploads; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_myemsl_uploads (
    entry_id integer NOT NULL,
    data_pkg_id integer NOT NULL,
    subfolder public.citext,
    file_count_new integer,
    file_count_updated integer,
    bytes bigint,
    upload_time_seconds real,
    status_uri_path_id integer,
    status_num integer,
    available smallint DEFAULT 0 NOT NULL,
    verified smallint DEFAULT 0 NOT NULL,
    error_code integer,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE dpkg.t_myemsl_uploads OWNER TO d3l243;

--
-- Name: t_myemsl_uploads_entry_id_seq; Type: SEQUENCE; Schema: dpkg; Owner: d3l243
--

ALTER TABLE dpkg.t_myemsl_uploads ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME dpkg.t_myemsl_uploads_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_myemsl_uploads pk_t_myemsl_uploads; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_myemsl_uploads
    ADD CONSTRAINT pk_t_myemsl_uploads PRIMARY KEY (entry_id);

--
-- Name: ix_t_myemsl_uploads_data_pkg_id; Type: INDEX; Schema: dpkg; Owner: d3l243
--

CREATE INDEX ix_t_myemsl_uploads_data_pkg_id ON dpkg.t_myemsl_uploads USING btree (data_pkg_id);

--
-- Name: ix_t_myemsl_uploads_entered; Type: INDEX; Schema: dpkg; Owner: d3l243
--

CREATE INDEX ix_t_myemsl_uploads_entered ON dpkg.t_myemsl_uploads USING btree (entered);

--
-- Name: ix_t_myemsl_uploads_error_code_status_num; Type: INDEX; Schema: dpkg; Owner: d3l243
--

CREATE INDEX ix_t_myemsl_uploads_error_code_status_num ON dpkg.t_myemsl_uploads USING btree (error_code, status_num);

--
-- Name: t_myemsl_uploads fk_t_myemsl_uploads_t_uri_paths_status_uri; Type: FK CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_myemsl_uploads
    ADD CONSTRAINT fk_t_myemsl_uploads_t_uri_paths_status_uri FOREIGN KEY (status_uri_path_id) REFERENCES dpkg.t_uri_paths(uri_path_id);

--
-- Name: TABLE t_myemsl_uploads; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_myemsl_uploads TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE dpkg.t_myemsl_uploads TO writeaccess;

