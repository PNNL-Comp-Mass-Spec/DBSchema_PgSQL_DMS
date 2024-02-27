--
-- Name: t_job_step_processing_log; Type: TABLE; Schema: logsw; Owner: d3l243
--

CREATE TABLE logsw.t_job_step_processing_log (
    event_id integer NOT NULL,
    job integer NOT NULL,
    step integer NOT NULL,
    processor public.citext NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE logsw.t_job_step_processing_log OWNER TO d3l243;

--
-- Name: t_job_step_processing_log ix_logsw_t_job_step_processing_log_unique_event_id; Type: CONSTRAINT; Schema: logsw; Owner: d3l243
--

ALTER TABLE ONLY logsw.t_job_step_processing_log
    ADD CONSTRAINT ix_logsw_t_job_step_processing_log_unique_event_id UNIQUE (event_id);

--
-- Name: t_job_step_processing_log pk_t_job_step_processing_log; Type: CONSTRAINT; Schema: logsw; Owner: d3l243
--

ALTER TABLE ONLY logsw.t_job_step_processing_log
    ADD CONSTRAINT pk_t_job_step_processing_log PRIMARY KEY (event_id);

--
-- Name: ix_t_job_step_processing_log_job_step; Type: INDEX; Schema: logsw; Owner: d3l243
--

CREATE INDEX ix_t_job_step_processing_log_job_step ON logsw.t_job_step_processing_log USING btree (job, step);

--
-- Name: ix_t_job_step_processing_log_processor; Type: INDEX; Schema: logsw; Owner: d3l243
--

CREATE INDEX ix_t_job_step_processing_log_processor ON logsw.t_job_step_processing_log USING btree (processor);

--
-- Name: TABLE t_job_step_processing_log; Type: ACL; Schema: logsw; Owner: d3l243
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE logsw.t_job_step_processing_log TO writeaccess;

