--
-- Name: t_jobs; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_jobs (
    job integer NOT NULL,
    priority integer,
    script public.citext NOT NULL,
    state integer DEFAULT 0 NOT NULL,
    dataset public.citext,
    dataset_id integer,
    results_folder_name public.citext,
    organism_db_name public.citext,
    imported timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    start timestamp without time zone,
    finish timestamp without time zone,
    runtime_minutes real,
    archive_busy smallint DEFAULT 0 NOT NULL,
    transfer_folder_path public.citext,
    comment public.citext,
    storage_server public.citext,
    special_processing public.citext,
    owner public.citext,
    data_pkg_id integer
);


ALTER TABLE sw.t_jobs OWNER TO d3l243;

--
-- Name: t_jobs pk_t_jobs; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_jobs
    ADD CONSTRAINT pk_t_jobs PRIMARY KEY (job);

--
-- Name: ix_t_jobs_dataset_id_include_job_state; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_jobs_dataset_id_include_job_state ON sw.t_jobs USING btree (dataset_id) INCLUDE (job, state);

--
-- Name: ix_t_jobs_state; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_jobs_state ON sw.t_jobs USING btree (state);

--
-- Name: ix_t_jobs_state_include_job_priority_arch_busy_storage_server; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_jobs_state_include_job_priority_arch_busy_storage_server ON sw.t_jobs USING btree (state) INCLUDE (job, priority, archive_busy, storage_server);

--
-- Name: t_jobs trig_t_jobs_after_delete; Type: TRIGGER; Schema: sw; Owner: d3l243
--

CREATE TRIGGER trig_t_jobs_after_delete AFTER DELETE ON sw.t_jobs REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION sw.trigfn_t_jobs_after_delete();

--
-- Name: t_jobs trig_t_jobs_after_insert; Type: TRIGGER; Schema: sw; Owner: d3l243
--

CREATE TRIGGER trig_t_jobs_after_insert AFTER INSERT ON sw.t_jobs REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION sw.trigfn_t_jobs_after_insert();

--
-- Name: t_jobs trig_t_jobs_after_update; Type: TRIGGER; Schema: sw; Owner: d3l243
--

CREATE TRIGGER trig_t_jobs_after_update AFTER UPDATE ON sw.t_jobs FOR EACH ROW WHEN ((old.state <> new.state)) EXECUTE FUNCTION sw.trigfn_t_jobs_after_update();

--
-- Name: t_jobs trig_t_jobs_after_update_all; Type: TRIGGER; Schema: sw; Owner: d3l243
--

CREATE TRIGGER trig_t_jobs_after_update_all AFTER UPDATE ON sw.t_jobs REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION sw.trigfn_t_jobs_after_update_all();

--
-- Name: t_jobs fk_t_jobs_t_job_state_name; Type: FK CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_jobs
    ADD CONSTRAINT fk_t_jobs_t_job_state_name FOREIGN KEY (state) REFERENCES sw.t_job_state_name(job_state_id);

--
-- Name: t_jobs fk_t_jobs_t_scripts; Type: FK CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_jobs
    ADD CONSTRAINT fk_t_jobs_t_scripts FOREIGN KEY (script) REFERENCES sw.t_scripts(script) ON UPDATE CASCADE;

--
-- Name: TABLE t_jobs; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_jobs TO readaccess;

