--
-- Name: t_job_step_events; Type: TABLE; Schema: logsw; Owner: d3l243
--

CREATE TABLE logsw.t_job_step_events (
    event_id integer NOT NULL,
    job integer NOT NULL,
    step integer NOT NULL,
    target_state integer NOT NULL,
    prev_target_state integer NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE logsw.t_job_step_events OWNER TO d3l243;

--
-- Name: t_job_step_events pk_t_job_step_events; Type: CONSTRAINT; Schema: logsw; Owner: d3l243
--

ALTER TABLE ONLY logsw.t_job_step_events
    ADD CONSTRAINT pk_t_job_step_events PRIMARY KEY (event_id);

--
-- Name: ix_t_job_step_events_current_state_job; Type: INDEX; Schema: logsw; Owner: d3l243
--

CREATE INDEX ix_t_job_step_events_current_state_job ON logsw.t_job_step_events USING btree (prev_target_state, job);

--
-- Name: ix_t_job_step_events_entered_include_job; Type: INDEX; Schema: logsw; Owner: d3l243
--

CREATE INDEX ix_t_job_step_events_entered_include_job ON logsw.t_job_step_events USING btree (entered) INCLUDE (job);

--
-- Name: ix_t_job_step_events_job; Type: INDEX; Schema: logsw; Owner: d3l243
--

CREATE INDEX ix_t_job_step_events_job ON logsw.t_job_step_events USING btree (job);

--
-- Name: TABLE t_job_step_events; Type: ACL; Schema: logsw; Owner: d3l243
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE logsw.t_job_step_events TO writeaccess;

