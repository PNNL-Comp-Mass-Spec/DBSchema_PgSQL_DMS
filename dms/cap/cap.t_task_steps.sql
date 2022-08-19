--
-- Name: t_task_steps; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_task_steps (
    job integer NOT NULL,
    step integer NOT NULL,
    step_tool public.citext NOT NULL,
    cpu_load smallint,
    dependencies smallint DEFAULT 0 NOT NULL,
    state smallint DEFAULT 1 NOT NULL,
    input_folder_name public.citext,
    output_folder_name public.citext,
    processor public.citext,
    start timestamp without time zone,
    finish timestamp without time zone,
    completion_code integer DEFAULT 0 NOT NULL,
    completion_message public.citext,
    evaluation_code integer,
    evaluation_message public.citext,
    job_plus_step public.citext GENERATED ALWAYS AS (((((job)::public.citext)::text || '.'::text) || ((step)::public.citext)::text)) STORED,
    holdoff_interval_minutes smallint DEFAULT 0,
    next_try timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    retry_count smallint DEFAULT 0,
    tool_version_id integer DEFAULT 1
);


ALTER TABLE cap.t_task_steps OWNER TO d3l243;

--
-- Name: t_task_steps pk_t_task_steps; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_task_steps
    ADD CONSTRAINT pk_t_task_steps PRIMARY KEY (job, step);

--
-- Name: ix_job_plus_step; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE UNIQUE INDEX ix_job_plus_step ON cap.t_task_steps USING btree (job_plus_step);

--
-- Name: ix_t_task_steps; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_steps ON cap.t_task_steps USING btree (job);

--
-- Name: ix_t_task_steps_dependencies_state_include_job_step; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_steps_dependencies_state_include_job_step ON cap.t_task_steps USING btree (dependencies, state) INCLUDE (job, step);

--
-- Name: ix_t_task_steps_output_folder_name_state; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_steps_output_folder_name_state ON cap.t_task_steps USING btree (output_folder_name, state);

--
-- Name: ix_t_task_steps_state; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_steps_state ON cap.t_task_steps USING btree (state);

--
-- Name: ix_t_task_steps_state_include_job_step_completion_code; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_steps_state_include_job_step_completion_code ON cap.t_task_steps USING btree (state) INCLUDE (completion_code, job, step);

--
-- Name: ix_t_task_steps_step_tool_state_next_try_include_job_step; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_steps_step_tool_state_next_try_include_job_step ON cap.t_task_steps USING btree (step_tool, state, next_try) INCLUDE (job, step);

--
-- Name: t_task_steps trig_t_task_steps_after_delete; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_task_steps_after_delete AFTER DELETE ON cap.t_task_steps REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION cap.trigfn_t_task_steps_after_delete();

--
-- Name: t_task_steps trig_t_task_steps_after_insert; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_task_steps_after_insert AFTER INSERT ON cap.t_task_steps REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION cap.trigfn_t_task_steps_after_insert();

--
-- Name: t_task_steps trig_t_task_steps_after_update; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_task_steps_after_update AFTER UPDATE ON cap.t_task_steps FOR EACH ROW WHEN ((old.state <> new.state)) EXECUTE FUNCTION cap.trigfn_t_task_steps_after_update();

--
-- Name: t_task_steps trig_t_task_steps_after_update_all; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_task_steps_after_update_all AFTER UPDATE ON cap.t_task_steps REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION cap.trigfn_t_task_steps_after_update_all();

--
-- Name: t_task_steps fk_t_task_steps_t_local_processors; Type: FK CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_task_steps
    ADD CONSTRAINT fk_t_task_steps_t_local_processors FOREIGN KEY (processor) REFERENCES cap.t_local_processors(processor_name);

--
-- Name: t_task_steps fk_t_task_steps_t_step_state; Type: FK CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_task_steps
    ADD CONSTRAINT fk_t_task_steps_t_step_state FOREIGN KEY (state) REFERENCES cap.t_task_step_state_name(step_state_id);

--
-- Name: t_task_steps fk_t_task_steps_t_step_tool_versions; Type: FK CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_task_steps
    ADD CONSTRAINT fk_t_task_steps_t_step_tool_versions FOREIGN KEY (tool_version_id) REFERENCES cap.t_step_tool_versions(tool_version_id);

--
-- Name: t_task_steps fk_t_task_steps_t_step_tools; Type: FK CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_task_steps
    ADD CONSTRAINT fk_t_task_steps_t_step_tools FOREIGN KEY (step_tool) REFERENCES cap.t_step_tools(step_tool);

--
-- Name: t_task_steps fk_t_task_steps_t_tasks; Type: FK CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_task_steps
    ADD CONSTRAINT fk_t_task_steps_t_tasks FOREIGN KEY (job) REFERENCES cap.t_tasks(job) ON DELETE CASCADE;

--
-- Name: TABLE t_task_steps; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_task_steps TO readaccess;

