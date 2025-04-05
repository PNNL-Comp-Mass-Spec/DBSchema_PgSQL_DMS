--
-- Name: t_data_repository_uploads; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_data_repository_uploads (
    upload_id integer NOT NULL,
    repository_id integer NOT NULL,
    title public.citext,
    upload_date timestamp without time zone,
    accession public.citext,
    contact public.citext
);


ALTER TABLE dpkg.t_data_repository_uploads OWNER TO d3l243;

--
-- Name: t_data_repository_uploads_upload_id_seq; Type: SEQUENCE; Schema: dpkg; Owner: d3l243
--

ALTER TABLE dpkg.t_data_repository_uploads ALTER COLUMN upload_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME dpkg.t_data_repository_uploads_upload_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_data_repository_uploads pk_t_data_repository_uploads; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_repository_uploads
    ADD CONSTRAINT pk_t_data_repository_uploads PRIMARY KEY (upload_id);

ALTER TABLE dpkg.t_data_repository_uploads CLUSTER ON pk_t_data_repository_uploads;

--
-- Name: ix_t_data_repository_uploads_accession; Type: INDEX; Schema: dpkg; Owner: d3l243
--

CREATE INDEX ix_t_data_repository_uploads_accession ON dpkg.t_data_repository_uploads USING btree (accession);

--
-- Name: t_data_repository_uploads fk_t_data_repository_uploads_t_data_repository; Type: FK CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_repository_uploads
    ADD CONSTRAINT fk_t_data_repository_uploads_t_data_repository FOREIGN KEY (repository_id) REFERENCES dpkg.t_data_repository(repository_id);

--
-- Name: TABLE t_data_repository_uploads; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_data_repository_uploads TO readaccess;
GRANT SELECT ON TABLE dpkg.t_data_repository_uploads TO writeaccess;

