--
-- Name: t_task_step_events; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_task_step_events (
    event_id integer NOT NULL,
    job integer NOT NULL,
    step integer NOT NULL,
    target_state integer NOT NULL,
    prev_target_state integer NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE cap.t_task_step_events OWNER TO d3l243;

--
-- Name: t_task_step_events_event_id_seq; Type: SEQUENCE; Schema: cap; Owner: d3l243
--

ALTER TABLE cap.t_task_step_events ALTER COLUMN event_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cap.t_task_step_events_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_task_step_events pk_t_task_step_events; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_task_step_events
    ADD CONSTRAINT pk_t_task_step_events PRIMARY KEY (event_id);

--
-- Name: ix_t_task_step_events_current_state_job; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_step_events_current_state_job ON cap.t_task_step_events USING btree (prev_target_state, job);

--
-- Name: ix_t_task_step_events_entered_include_job; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_step_events_entered_include_job ON cap.t_task_step_events USING btree (entered) INCLUDE (job);

--
-- Name: ix_t_task_step_events_job; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_step_events_job ON cap.t_task_step_events USING btree (job);

