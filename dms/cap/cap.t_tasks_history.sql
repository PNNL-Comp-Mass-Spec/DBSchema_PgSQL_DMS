--
-- Name: t_tasks_history; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_tasks_history (
    job integer NOT NULL,
    priority integer,
    script public.citext,
    state integer NOT NULL,
    dataset public.citext,
    dataset_id integer,
    results_folder_name public.citext,
    imported timestamp without time zone,
    start timestamp without time zone,
    finish timestamp without time zone,
    saved timestamp without time zone NOT NULL,
    most_recent_entry smallint DEFAULT 0 NOT NULL
);


ALTER TABLE cap.t_tasks_history OWNER TO d3l243;

--
-- Name: t_tasks_history pk_t_tasks_history; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_tasks_history
    ADD CONSTRAINT pk_t_tasks_history PRIMARY KEY (job, saved);

--
-- Name: ix_t_tasks_history_dataset; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_history_dataset ON cap.t_tasks_history USING btree (dataset);

--
-- Name: ix_t_tasks_history_dataset_id; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_history_dataset_id ON cap.t_tasks_history USING btree (dataset_id);

--
-- Name: ix_t_tasks_history_dataset_lower_text_pattern_ops; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_history_dataset_lower_text_pattern_ops ON cap.t_tasks_history USING btree (lower((dataset)::text) text_pattern_ops);

--
-- Name: ix_t_tasks_history_job; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_history_job ON cap.t_tasks_history USING btree (job);

--
-- Name: ix_t_tasks_history_newest_entry_include_job_script_ds; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_history_newest_entry_include_job_script_ds ON cap.t_tasks_history USING btree (most_recent_entry) INCLUDE (job, script, dataset);

--
-- Name: ix_t_tasks_history_script_job; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_history_script_job ON cap.t_tasks_history USING btree (script) INCLUDE (job);

--
-- Name: ix_t_tasks_history_state_include_job; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_history_state_include_job ON cap.t_tasks_history USING btree (state) INCLUDE (job);

--
-- Name: t_tasks_history trig_t_tasks_history_after_delete; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_tasks_history_after_delete AFTER DELETE ON cap.t_tasks_history REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION cap.trigfn_t_tasks_history_after_delete();

--
-- Name: t_tasks_history trig_t_tasks_history_after_insert; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_tasks_history_after_insert AFTER INSERT ON cap.t_tasks_history REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION cap.trigfn_t_tasks_history_after_insert();

--
-- Name: t_tasks_history trig_t_tasks_history_after_update; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_tasks_history_after_update AFTER UPDATE ON cap.t_tasks_history FOR EACH ROW WHEN ((old.saved <> new.saved)) EXECUTE FUNCTION cap.trigfn_t_tasks_history_after_update();

--
-- Name: TABLE t_tasks_history; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_tasks_history TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE cap.t_tasks_history TO writeaccess;

