--
-- Name: t_job_steps_history; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_job_steps_history (
    job integer NOT NULL,
    step integer NOT NULL,
    priority integer,
    step_tool public.citext NOT NULL,
    shared_result_version smallint,
    signature integer,
    state smallint,
    input_folder_name public.citext,
    output_folder_name public.citext,
    processor public.citext,
    start timestamp without time zone,
    finish timestamp without time zone,
    completion_code integer,
    completion_message public.citext,
    evaluation_code integer,
    evaluation_message public.citext,
    saved timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    job_step_saved_combo public.citext GENERATED ALWAYS AS (((((((job)::public.citext)::text || '.'::text) || ((step)::public.citext)::text) || '.'::text) || public.timestamp_text_immutable(saved))) STORED,
    most_recent_entry smallint DEFAULT 0 NOT NULL,
    tool_version_id integer,
    memory_usage_mb integer,
    remote_info_id integer,
    remote_start timestamp without time zone,
    remote_finish timestamp without time zone
);


ALTER TABLE sw.t_job_steps_history OWNER TO d3l243;

--
-- Name: t_job_steps_history pk_t_job_steps_history; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_steps_history
    ADD CONSTRAINT pk_t_job_steps_history PRIMARY KEY (job, step, saved);

--
-- Name: ix_t_job_steps_history_finish; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_steps_history_finish ON sw.t_job_steps_history USING btree (finish);

--
-- Name: ix_t_job_steps_history_job_step; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_steps_history_job_step ON sw.t_job_steps_history USING btree (job, step);

--
-- Name: ix_t_job_steps_history_job_step_saved_combo; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_job_steps_history_job_step_saved_combo ON sw.t_job_steps_history USING btree (job_step_saved_combo);

--
-- Name: ix_t_job_steps_history_most_recent_entry; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_steps_history_most_recent_entry ON sw.t_job_steps_history USING btree (most_recent_entry);

--
-- Name: ix_t_job_steps_history_state_output_folder_name; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_steps_history_state_output_folder_name ON sw.t_job_steps_history USING btree (state, output_folder_name);

--
-- Name: ix_t_job_steps_history_step_tool_start; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_steps_history_step_tool_start ON sw.t_job_steps_history USING btree (step_tool, start);

--
-- Name: t_job_steps_history_tool_version_id; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX t_job_steps_history_tool_version_id ON sw.t_job_steps_history USING btree (tool_version_id);

