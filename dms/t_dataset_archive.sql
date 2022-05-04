--
-- Name: t_dataset_archive; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_archive (
    dataset_id integer NOT NULL,
    archive_state_id integer NOT NULL,
    archive_state_last_affected timestamp without time zone,
    storage_path_id integer NOT NULL,
    archive_date timestamp without time zone,
    last_update timestamp without time zone,
    last_verify timestamp without time zone,
    archive_update_state_id integer,
    archive_update_state_last_affected timestamp without time zone,
    purge_holdoff_date timestamp without time zone,
    archive_processor public.citext,
    update_processor public.citext,
    verification_processor public.citext,
    instrument_data_purged smallint DEFAULT 0 NOT NULL,
    last_successful_archive timestamp without time zone,
    stagemd5_required smallint DEFAULT 0 NOT NULL,
    qc_data_purged smallint DEFAULT 0 NOT NULL,
    purge_policy smallint DEFAULT 0 NOT NULL,
    purge_priority smallint DEFAULT 3 NOT NULL,
    myemsl_state smallint DEFAULT 0 NOT NULL
);


ALTER TABLE public.t_dataset_archive OWNER TO d3l243;

--
-- Name: t_dataset_archive pk_t_dataset_archive; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_archive
    ADD CONSTRAINT pk_t_dataset_archive PRIMARY KEY (dataset_id);

--
-- Name: ix_dataset_archive_dataset_id_state_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_dataset_archive_dataset_id_state_id ON public.t_dataset_archive USING btree (dataset_id, archive_state_id);

--
-- Name: ix_t_dataset_archive_last_successful_archive; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_archive_last_successful_archive ON public.t_dataset_archive USING btree (last_successful_archive);

--
-- Name: ix_t_dataset_archive_stage_md5_required_include_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_archive_stage_md5_required_include_dataset_id ON public.t_dataset_archive USING btree (stagemd5_required) INCLUDE (dataset_id, purge_holdoff_date);

--
-- Name: ix_t_dataset_archive_state; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_archive_state ON public.t_dataset_archive USING btree (archive_state_id);

--
-- Name: ix_t_dataset_archive_state_id_update_state_id_include_dataset; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_archive_state_id_update_state_id_include_dataset ON public.t_dataset_archive USING btree (archive_state_id, archive_update_state_id) INCLUDE (dataset_id, purge_holdoff_date, stagemd5_required);

--
-- Name: ix_t_dataset_archive_storage_path_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_archive_storage_path_id ON public.t_dataset_archive USING btree (storage_path_id);

--
-- Name: ix_t_dataset_archive_update_state_id_dataset_id_state_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_archive_update_state_id_dataset_id_state_id ON public.t_dataset_archive USING btree (archive_update_state_id, dataset_id, archive_state_id) INCLUDE (purge_holdoff_date);

--
-- Name: TABLE t_dataset_archive; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_archive TO readaccess;

