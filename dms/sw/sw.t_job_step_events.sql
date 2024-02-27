--
-- Name: t_job_step_events; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_job_step_events (
    event_id integer NOT NULL,
    job integer NOT NULL,
    step integer NOT NULL,
    target_state integer NOT NULL,
    prev_target_state integer NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE sw.t_job_step_events OWNER TO d3l243;

--
-- Name: t_job_step_events_event_id_seq; Type: SEQUENCE; Schema: sw; Owner: d3l243
--

ALTER TABLE sw.t_job_step_events ALTER COLUMN event_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sw.t_job_step_events_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_job_step_events pk_t_job_step_events; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_step_events
    ADD CONSTRAINT pk_t_job_step_events PRIMARY KEY (event_id);

--
-- Name: ix_t_job_step_events_current_state_job; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_step_events_current_state_job ON sw.t_job_step_events USING btree (prev_target_state, job);

--
-- Name: ix_t_job_step_events_entered_include_job; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_step_events_entered_include_job ON sw.t_job_step_events USING btree (entered) INCLUDE (job);

--
-- Name: ix_t_job_step_events_job; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_step_events_job ON sw.t_job_step_events USING btree (job);

--
-- Name: TABLE t_job_step_events; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_job_step_events TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sw.t_job_step_events TO writeaccess;

