--
-- Name: t_myemsl_upload_resets; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_myemsl_upload_resets (
    entry_id integer NOT NULL,
    job integer NOT NULL,
    dataset_id integer NOT NULL,
    subfolder public.citext,
    error_message public.citext,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE cap.t_myemsl_upload_resets OWNER TO d3l243;

--
-- Name: t_myemsl_upload_resets_entry_id_seq; Type: SEQUENCE; Schema: cap; Owner: d3l243
--

ALTER TABLE cap.t_myemsl_upload_resets ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cap.t_myemsl_upload_resets_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_myemsl_upload_resets pk_t_myemsl_upload_resets; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_myemsl_upload_resets
    ADD CONSTRAINT pk_t_myemsl_upload_resets PRIMARY KEY (entry_id);

--
-- Name: ix_t_myemsl_upload_resets_dataset_id; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_myemsl_upload_resets_dataset_id ON cap.t_myemsl_upload_resets USING btree (dataset_id);

--
-- Name: ix_t_myemsl_upload_resets_entered; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_myemsl_upload_resets_entered ON cap.t_myemsl_upload_resets USING btree (entered);

--
-- Name: ix_t_myemsl_upload_resets_job; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_myemsl_upload_resets_job ON cap.t_myemsl_upload_resets USING btree (job);

--
-- Name: TABLE t_myemsl_upload_resets; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_myemsl_upload_resets TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE cap.t_myemsl_upload_resets TO writeaccess;

