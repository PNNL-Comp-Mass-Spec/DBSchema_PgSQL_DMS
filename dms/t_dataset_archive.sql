--
-- Name: t_dataset_archive; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_archive (
    dataset_id integer NOT NULL,
    archive_state_id integer NOT NULL,
    archive_state_last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
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
-- Name: t_dataset_archive trig_t_dataset_archive_after_delete; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_dataset_archive_after_delete AFTER DELETE ON public.t_dataset_archive REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_dataset_archive_after_delete();

--
-- Name: t_dataset_archive trig_t_dataset_archive_after_insert; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_dataset_archive_after_insert AFTER INSERT ON public.t_dataset_archive REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_dataset_archive_after_insert();

--
-- Name: t_dataset_archive trig_t_dataset_archive_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_dataset_archive_after_update AFTER UPDATE ON public.t_dataset_archive FOR EACH ROW WHEN (((old.archive_state_id <> new.archive_state_id) OR (old.archive_update_state_id IS DISTINCT FROM new.archive_update_state_id) OR (old.storage_path_id <> new.storage_path_id) OR (old.instrument_data_purged <> new.instrument_data_purged) OR (old.qc_data_purged <> new.qc_data_purged) OR (old.myemsl_state <> new.myemsl_state))) EXECUTE FUNCTION public.trigfn_t_dataset_archive_after_update();

--
-- Name: t_dataset_archive fk_t_dataset_archive_t_archive_path; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_archive
    ADD CONSTRAINT fk_t_dataset_archive_t_archive_path FOREIGN KEY (storage_path_id) REFERENCES public.t_archive_path(archive_path_id);

--
-- Name: t_dataset_archive fk_t_dataset_archive_t_archive_update_state_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_archive
    ADD CONSTRAINT fk_t_dataset_archive_t_archive_update_state_name FOREIGN KEY (archive_update_state_id) REFERENCES public.t_archive_update_state_name(archive_update_state_id);

--
-- Name: t_dataset_archive fk_t_dataset_archive_t_dataset; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_archive
    ADD CONSTRAINT fk_t_dataset_archive_t_dataset FOREIGN KEY (dataset_id) REFERENCES public.t_dataset(dataset_id);

--
-- Name: t_dataset_archive fk_t_dataset_archive_t_dataset_archive_state_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_archive
    ADD CONSTRAINT fk_t_dataset_archive_t_dataset_archive_state_name FOREIGN KEY (archive_state_id) REFERENCES public.t_dataset_archive_state_name(archive_state_id);

--
-- Name: t_dataset_archive fk_t_dataset_archive_t_myemsl_state; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_archive
    ADD CONSTRAINT fk_t_dataset_archive_t_myemsl_state FOREIGN KEY (myemsl_state) REFERENCES public.t_myemsl_state(myemsl_state);

--
-- Name: t_dataset_archive fk_t_dataset_archive_t_yes_no; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_archive
    ADD CONSTRAINT fk_t_dataset_archive_t_yes_no FOREIGN KEY (instrument_data_purged) REFERENCES public.t_yes_no(flag);

--
-- Name: TABLE t_dataset_archive; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_archive TO readaccess;

