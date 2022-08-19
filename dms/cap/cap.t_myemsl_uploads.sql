--
-- Name: t_myemsl_uploads; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_myemsl_uploads (
    entry_id integer NOT NULL,
    job integer NOT NULL,
    dataset_id integer NOT NULL,
    subfolder public.citext,
    file_count_new integer,
    file_count_updated integer,
    bytes bigint,
    upload_time_seconds real,
    status_uri_path_id integer,
    content_uri_path_id integer,
    status_num integer,
    transaction_id integer,
    verified smallint DEFAULT 0 NOT NULL,
    ingest_steps_completed smallint,
    error_code integer,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    eus_instrument_id integer,
    eus_proposal_id public.citext,
    eus_uploader_id integer
);


ALTER TABLE cap.t_myemsl_uploads OWNER TO d3l243;

--
-- Name: t_myemsl_uploads_entry_id_seq; Type: SEQUENCE; Schema: cap; Owner: d3l243
--

ALTER TABLE cap.t_myemsl_uploads ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cap.t_myemsl_uploads_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_myemsl_uploads pk_t_myemsl_uploads; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_myemsl_uploads
    ADD CONSTRAINT pk_t_myemsl_uploads PRIMARY KEY (entry_id);

--
-- Name: ix_t_myemsl_uploads_dataset_id_include_status_num; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_myemsl_uploads_dataset_id_include_status_num ON cap.t_myemsl_uploads USING btree (dataset_id) INCLUDE (status_num);

--
-- Name: ix_t_myemsl_uploads_dataset_id_status_uripath_id_verified; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_myemsl_uploads_dataset_id_status_uripath_id_verified ON cap.t_myemsl_uploads USING btree (dataset_id, status_uri_path_id, verified) INCLUDE (transaction_id);

--
-- Name: ix_t_myemsl_uploads_entered; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_myemsl_uploads_entered ON cap.t_myemsl_uploads USING btree (entered);

--
-- Name: ix_t_myemsl_uploads_job; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_myemsl_uploads_job ON cap.t_myemsl_uploads USING btree (job);

--
-- Name: ix_t_myemsl_uploads_status_num_include_entry_id; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_myemsl_uploads_status_num_include_entry_id ON cap.t_myemsl_uploads USING btree (status_num) INCLUDE (entry_id);

--
-- Name: t_myemsl_uploads fk_t_myemsl_uploads_t_uri_paths_content_uri; Type: FK CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_myemsl_uploads
    ADD CONSTRAINT fk_t_myemsl_uploads_t_uri_paths_content_uri FOREIGN KEY (content_uri_path_id) REFERENCES cap.t_uri_paths(uri_path_id);

--
-- Name: t_myemsl_uploads fk_t_myemsl_uploads_t_uri_paths_status_uri; Type: FK CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_myemsl_uploads
    ADD CONSTRAINT fk_t_myemsl_uploads_t_uri_paths_status_uri FOREIGN KEY (status_uri_path_id) REFERENCES cap.t_uri_paths(uri_path_id);

--
-- Name: TABLE t_myemsl_uploads; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_myemsl_uploads TO readaccess;
GRANT SELECT ON TABLE cap.t_myemsl_uploads TO writeaccess;

