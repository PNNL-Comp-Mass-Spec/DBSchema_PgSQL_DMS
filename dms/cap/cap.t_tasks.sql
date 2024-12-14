--
-- Name: t_tasks; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_tasks (
    job integer NOT NULL,
    priority integer DEFAULT 4,
    script public.citext NOT NULL,
    state integer DEFAULT 0 NOT NULL,
    dataset public.citext,
    dataset_id integer,
    storage_server public.citext,
    instrument public.citext,
    instrument_class public.citext,
    max_simultaneous_captures integer,
    results_folder_name public.citext,
    imported timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    start timestamp without time zone,
    finish timestamp without time zone,
    archive_busy smallint DEFAULT 0 NOT NULL,
    transfer_folder_path public.citext,
    comment public.citext,
    capture_subfolder public.citext
);


ALTER TABLE cap.t_tasks OWNER TO d3l243;

--
-- Name: t_tasks_job_seq; Type: SEQUENCE; Schema: cap; Owner: d3l243
--

ALTER TABLE cap.t_tasks ALTER COLUMN job ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cap.t_tasks_job_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_tasks pk_t_tasks; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_tasks
    ADD CONSTRAINT pk_t_tasks PRIMARY KEY (job);

--
-- Name: ix_t_tasks_dataset; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_dataset ON cap.t_tasks USING btree (dataset);

--
-- Name: ix_t_tasks_dataset_id; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_dataset_id ON cap.t_tasks USING btree (dataset_id);

--
-- Name: ix_t_tasks_dataset_lower_text_pattern_ops; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_dataset_lower_text_pattern_ops ON cap.t_tasks USING btree (lower((dataset)::text) text_pattern_ops);

--
-- Name: ix_t_tasks_script_dataset; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_script_dataset ON cap.t_tasks USING btree (script, dataset);

--
-- Name: ix_t_tasks_script_dataset_id; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_script_dataset_id ON cap.t_tasks USING btree (script, dataset_id);

--
-- Name: ix_t_tasks_script_state_include_dataset_id_results_finish; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_script_state_include_dataset_id_results_finish ON cap.t_tasks USING btree (script, state) INCLUDE (dataset_id, results_folder_name, finish);

--
-- Name: ix_t_tasks_script_state_include_job_dataset_dataset_id; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_script_state_include_job_dataset_dataset_id ON cap.t_tasks USING btree (script, state) INCLUDE (job, dataset, dataset_id);

--
-- Name: ix_t_tasks_state; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_state ON cap.t_tasks USING btree (state);

--
-- Name: ix_t_tasks_state_include_job_priority_archive_busy; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_state_include_job_priority_archive_busy ON cap.t_tasks USING btree (state) INCLUDE (archive_busy, job, priority);

--
-- Name: t_tasks trig_t_tasks_after_delete; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_tasks_after_delete AFTER DELETE ON cap.t_tasks REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION cap.trigfn_t_tasks_after_delete();

--
-- Name: t_tasks trig_t_tasks_after_insert; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_tasks_after_insert AFTER INSERT ON cap.t_tasks REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION cap.trigfn_t_tasks_after_insert();

--
-- Name: t_tasks trig_t_tasks_after_update; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_tasks_after_update AFTER UPDATE ON cap.t_tasks FOR EACH ROW WHEN ((old.state <> new.state)) EXECUTE FUNCTION cap.trigfn_t_tasks_after_update();

--
-- Name: t_tasks trig_t_tasks_after_update_all; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_tasks_after_update_all AFTER UPDATE ON cap.t_tasks REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION cap.trigfn_t_tasks_after_update_all();

--
-- Name: t_tasks fk_t_tasks_t_scripts; Type: FK CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_tasks
    ADD CONSTRAINT fk_t_tasks_t_scripts FOREIGN KEY (script) REFERENCES cap.t_scripts(script);

--
-- Name: t_tasks fk_t_tasks_t_task_state_name; Type: FK CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_tasks
    ADD CONSTRAINT fk_t_tasks_t_task_state_name FOREIGN KEY (state) REFERENCES cap.t_task_state_name(job_state_id);

--
-- Name: TABLE t_tasks; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_tasks TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE cap.t_tasks TO writeaccess;

