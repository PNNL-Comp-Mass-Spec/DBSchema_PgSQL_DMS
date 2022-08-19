--
-- Name: t_job_steps; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_job_steps (
    job integer NOT NULL,
    step integer NOT NULL,
    step_tool public.citext NOT NULL,
    cpu_load smallint,
    actual_cpu_load smallint,
    dependencies smallint DEFAULT 0 NOT NULL,
    shared_result_version smallint,
    signature integer,
    state smallint DEFAULT 1 NOT NULL,
    input_folder_name public.citext,
    output_folder_name public.citext,
    processor public.citext,
    start timestamp without time zone,
    finish timestamp without time zone,
    completion_code integer DEFAULT 0,
    completion_message public.citext,
    evaluation_code integer,
    evaluation_message public.citext,
    job_plus_step public.citext GENERATED ALWAYS AS (((((job)::public.citext)::text || '.'::text) || ((step)::public.citext)::text)) STORED,
    tool_version_id integer DEFAULT 1,
    memory_usage_mb integer,
    next_try timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    retry_count smallint DEFAULT 0 NOT NULL,
    remote_info_id integer DEFAULT 1 NOT NULL,
    remote_timestamp public.citext,
    remote_start timestamp without time zone,
    remote_finish timestamp without time zone,
    remote_progress real
);


ALTER TABLE sw.t_job_steps OWNER TO d3l243;

--
-- Name: t_job_steps pk_t_job_steps; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_steps
    ADD CONSTRAINT pk_t_job_steps PRIMARY KEY (job, step);

--
-- Name: ix_job_plus_step; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE UNIQUE INDEX ix_job_plus_step ON sw.t_job_steps USING btree (job_plus_step);

--
-- Name: ix_t_job_steps; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_steps ON sw.t_job_steps USING btree (job);

--
-- Name: ix_t_job_steps_dependencies_state_include_job_step; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_steps_dependencies_state_include_job_step ON sw.t_job_steps USING btree (dependencies, state) INCLUDE (job, step);

--
-- Name: ix_t_job_steps_output_folder_name_state; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_steps_output_folder_name_state ON sw.t_job_steps USING btree (output_folder_name, state);

--
-- Name: ix_t_job_steps_state; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_steps_state ON sw.t_job_steps USING btree (state);

--
-- Name: ix_t_job_steps_state_include_job_step_completion_code; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_steps_state_include_job_step_completion_code ON sw.t_job_steps USING btree (state) INCLUDE (job, step, completion_code);

--
-- Name: ix_t_job_steps_state_job_step_dep_shared_results_ver_sig_tool; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_steps_state_job_step_dep_shared_results_ver_sig_tool ON sw.t_job_steps USING btree (state, job, step, dependencies, shared_result_version, signature, step_tool);

--
-- Name: ix_t_job_steps_step_tool_state; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_steps_step_tool_state ON sw.t_job_steps USING btree (step_tool, state);

--
-- Name: ix_t_job_steps_tool_state_next_try_include_job_step_memory; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_steps_tool_state_next_try_include_job_step_memory ON sw.t_job_steps USING btree (step_tool, state, next_try) INCLUDE (job, step, memory_usage_mb, remote_info_id);

--
-- Name: t_job_steps trig_t_job_steps_after_delete; Type: TRIGGER; Schema: sw; Owner: d3l243
--

CREATE TRIGGER trig_t_job_steps_after_delete AFTER DELETE ON sw.t_job_steps REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION sw.trigfn_t_job_steps_after_delete();

--
-- Name: t_job_steps trig_t_job_steps_after_insert; Type: TRIGGER; Schema: sw; Owner: d3l243
--

CREATE TRIGGER trig_t_job_steps_after_insert AFTER INSERT ON sw.t_job_steps REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION sw.trigfn_t_job_steps_after_insert();

--
-- Name: t_job_steps trig_t_job_steps_after_update; Type: TRIGGER; Schema: sw; Owner: d3l243
--

CREATE TRIGGER trig_t_job_steps_after_update AFTER UPDATE ON sw.t_job_steps FOR EACH ROW WHEN ((old.state <> new.state)) EXECUTE FUNCTION sw.trigfn_t_job_steps_after_update();

--
-- Name: t_job_steps trig_t_job_steps_after_update_all; Type: TRIGGER; Schema: sw; Owner: d3l243
--

CREATE TRIGGER trig_t_job_steps_after_update_all AFTER UPDATE ON sw.t_job_steps REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION sw.trigfn_t_job_steps_after_update_all();

--
-- Name: t_job_steps fk_t_job_steps_t_jobs; Type: FK CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_steps
    ADD CONSTRAINT fk_t_job_steps_t_jobs FOREIGN KEY (job) REFERENCES sw.t_jobs(job) ON DELETE CASCADE;

--
-- Name: t_job_steps fk_t_job_steps_t_remote_info; Type: FK CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_steps
    ADD CONSTRAINT fk_t_job_steps_t_remote_info FOREIGN KEY (remote_info_id) REFERENCES sw.t_remote_info(remote_info_id);

--
-- Name: t_job_steps fk_t_job_steps_t_signatures; Type: FK CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_steps
    ADD CONSTRAINT fk_t_job_steps_t_signatures FOREIGN KEY (signature) REFERENCES sw.t_signatures(reference);

--
-- Name: t_job_steps fk_t_job_steps_t_step_state; Type: FK CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_steps
    ADD CONSTRAINT fk_t_job_steps_t_step_state FOREIGN KEY (state) REFERENCES sw.t_job_step_state_name(step_state_id);

--
-- Name: t_job_steps fk_t_job_steps_t_step_tool_versions; Type: FK CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_steps
    ADD CONSTRAINT fk_t_job_steps_t_step_tool_versions FOREIGN KEY (tool_version_id) REFERENCES sw.t_step_tool_versions(tool_version_id);

--
-- Name: t_job_steps fk_t_job_steps_t_step_tools; Type: FK CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_steps
    ADD CONSTRAINT fk_t_job_steps_t_step_tools FOREIGN KEY (step_tool) REFERENCES sw.t_step_tools(step_tool) ON UPDATE CASCADE;

--
-- Name: TABLE t_job_steps; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_job_steps TO readaccess;
GRANT SELECT ON TABLE sw.t_job_steps TO writeaccess;

