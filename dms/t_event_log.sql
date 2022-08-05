--
-- Name: t_event_log; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_event_log (
    event_id integer NOT NULL,
    target_type integer,
    target_id integer,
    target_state smallint,
    prev_target_state smallint,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE public.t_event_log OWNER TO d3l243;

--
-- Name: t_event_log_event_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_event_log ALTER COLUMN event_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_event_log_event_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_event_log pk_t_event_log; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_event_log
    ADD CONSTRAINT pk_t_event_log PRIMARY KEY (event_id);

--
-- Name: ix_t_event_log_entered; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_event_log_entered ON public.t_event_log USING btree (entered);

--
-- Name: ix_t_event_log_prev_target_state_target_state_target_type; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_event_log_prev_target_state_target_state_target_type ON public.t_event_log USING btree (prev_target_state, target_state, target_type);

--
-- Name: ix_t_event_log_target_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_event_log_target_id ON public.t_event_log USING btree (target_id);

--
-- Name: ix_t_event_log_target_id_prev_target_state_target_state; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_event_log_target_id_prev_target_state_target_state ON public.t_event_log USING btree (target_id, prev_target_state, target_state);

--
-- Name: ix_t_event_log_target_type_target_state_entered; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_event_log_target_type_target_state_entered ON public.t_event_log USING btree (target_type, target_state, entered) INCLUDE (event_id);

--
-- Name: t_event_log fk_t_event_log_t_event_target1; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_event_log
    ADD CONSTRAINT fk_t_event_log_t_event_target1 FOREIGN KEY (target_type) REFERENCES public.t_event_target(target_type_id);

--
-- Name: TABLE t_event_log; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_event_log TO readaccess;

