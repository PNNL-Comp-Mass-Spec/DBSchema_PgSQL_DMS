--
-- Name: t_task_events; Type: TABLE; Schema: logcap; Owner: d3l243
--

CREATE TABLE logcap.t_task_events (
    id integer NOT NULL,
    event_id integer NOT NULL,
    job integer NOT NULL,
    target_state integer NOT NULL,
    prev_target_state integer NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE logcap.t_task_events OWNER TO d3l243;

--
-- Name: t_task_events pk_t_task_events; Type: CONSTRAINT; Schema: logcap; Owner: d3l243
--

ALTER TABLE ONLY logcap.t_task_events
    ADD CONSTRAINT pk_t_task_events PRIMARY KEY (id);

--
-- Name: ix_t_task_events_current_state_job; Type: INDEX; Schema: logcap; Owner: d3l243
--

CREATE INDEX ix_t_task_events_current_state_job ON logcap.t_task_events USING btree (prev_target_state, job);

--
-- Name: ix_t_task_events_entered; Type: INDEX; Schema: logcap; Owner: d3l243
--

CREATE INDEX ix_t_task_events_entered ON logcap.t_task_events USING btree (entered);

--
-- Name: ix_t_task_events_event_id; Type: INDEX; Schema: logcap; Owner: d3l243
--

CREATE INDEX ix_t_task_events_event_id ON logcap.t_task_events USING btree (event_id);

--
-- Name: ix_t_task_events_job; Type: INDEX; Schema: logcap; Owner: d3l243
--

CREATE INDEX ix_t_task_events_job ON logcap.t_task_events USING btree (job);

--
-- Name: TABLE t_task_events; Type: ACL; Schema: logcap; Owner: d3l243
--

GRANT SELECT ON TABLE logcap.t_task_events TO writeaccess;
