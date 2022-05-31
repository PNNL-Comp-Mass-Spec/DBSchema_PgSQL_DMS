--
-- Name: t_job_parameters_history; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_job_parameters_history (
    job integer NOT NULL,
    parameters xml,
    saved timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    most_recent_entry smallint DEFAULT 0 NOT NULL
);


ALTER TABLE sw.t_job_parameters_history OWNER TO d3l243;

--
-- Name: t_job_parameters_history pk_t_job_parameters_history; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_parameters_history
    ADD CONSTRAINT pk_t_job_parameters_history PRIMARY KEY (job, saved);

--
-- Name: ix_t_job_parameters_history_most_recent_entry; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_parameters_history_most_recent_entry ON sw.t_job_parameters_history USING btree (most_recent_entry);

