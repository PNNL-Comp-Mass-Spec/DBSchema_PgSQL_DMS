--
-- Name: t_jobs_history; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_jobs_history (
    job integer NOT NULL,
    priority integer,
    script public.citext,
    state integer NOT NULL,
    dataset public.citext,
    dataset_id integer,
    results_folder_name public.citext,
    organism_db_name public.citext,
    special_processing public.citext,
    imported timestamp without time zone,
    start timestamp without time zone,
    finish timestamp without time zone,
    runtime_minutes real,
    saved timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    most_recent_entry smallint DEFAULT 0 NOT NULL,
    transfer_folder_path public.citext,
    owner public.citext,
    data_pkg_id integer,
    comment public.citext
);


ALTER TABLE sw.t_jobs_history OWNER TO d3l243;

--
-- Name: t_jobs_history pk_t_jobs_history; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_jobs_history
    ADD CONSTRAINT pk_t_jobs_history PRIMARY KEY (job, saved);

--
-- Name: ix_t_jobs_history_data_pkg_id; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_jobs_history_data_pkg_id ON sw.t_jobs_history USING btree (data_pkg_id);

--
-- Name: ix_t_jobs_history_dataset; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_jobs_history_dataset ON sw.t_jobs_history USING btree (dataset);

--
-- Name: ix_t_jobs_history_job; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_jobs_history_job ON sw.t_jobs_history USING btree (job);

--
-- Name: ix_t_jobs_history_most_recent_entry_include_job_script_dataset; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_jobs_history_most_recent_entry_include_job_script_dataset ON sw.t_jobs_history USING btree (most_recent_entry) INCLUDE (job, script, dataset);

--
-- Name: ix_t_jobs_history_script_job; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_jobs_history_script_job ON sw.t_jobs_history USING btree (script) INCLUDE (job);

--
-- Name: ix_t_jobs_history_state_include_job; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_jobs_history_state_include_job ON sw.t_jobs_history USING btree (state) INCLUDE (job);

