--
-- Name: t_job_events; Type: TABLE; Schema: logsw; Owner: d3l243
--

CREATE TABLE logsw.t_job_events (
    event_id integer NOT NULL,
    job integer NOT NULL,
    target_state integer NOT NULL,
    prev_target_state integer NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE logsw.t_job_events OWNER TO d3l243;

--
-- Name: t_job_events pk_t_job_events; Type: CONSTRAINT; Schema: logsw; Owner: d3l243
--

ALTER TABLE ONLY logsw.t_job_events
    ADD CONSTRAINT pk_t_job_events PRIMARY KEY (event_id);

--
-- Name: ix_t_job_events_current_state_job; Type: INDEX; Schema: logsw; Owner: d3l243
--

CREATE INDEX ix_t_job_events_current_state_job ON logsw.t_job_events USING btree (prev_target_state, job);

--
-- Name: ix_t_job_events_entered; Type: INDEX; Schema: logsw; Owner: d3l243
--

CREATE INDEX ix_t_job_events_entered ON logsw.t_job_events USING btree (entered);

--
-- Name: ix_t_job_events_job; Type: INDEX; Schema: logsw; Owner: d3l243
--

CREATE INDEX ix_t_job_events_job ON logsw.t_job_events USING btree (job);

