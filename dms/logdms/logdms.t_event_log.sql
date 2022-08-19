--
-- Name: t_event_log; Type: TABLE; Schema: logdms; Owner: d3l243
--

CREATE TABLE logdms.t_event_log (
    event_id integer NOT NULL,
    target_type integer,
    target_id integer,
    target_state smallint,
    prev_target_state smallint,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE logdms.t_event_log OWNER TO d3l243;

--
-- Name: t_event_log pk_t_event_log; Type: CONSTRAINT; Schema: logdms; Owner: d3l243
--

ALTER TABLE ONLY logdms.t_event_log
    ADD CONSTRAINT pk_t_event_log PRIMARY KEY (event_id);

--
-- Name: ix_t_event_log_entered; Type: INDEX; Schema: logdms; Owner: d3l243
--

CREATE INDEX ix_t_event_log_entered ON logdms.t_event_log USING btree (entered);

--
-- Name: ix_t_event_log_target_id; Type: INDEX; Schema: logdms; Owner: d3l243
--

CREATE INDEX ix_t_event_log_target_id ON logdms.t_event_log USING btree (target_id);

--
-- Name: TABLE t_event_log; Type: ACL; Schema: logdms; Owner: d3l243
--

GRANT SELECT ON TABLE logdms.t_event_log TO writeaccess;

