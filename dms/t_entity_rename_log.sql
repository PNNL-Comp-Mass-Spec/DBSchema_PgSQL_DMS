--
-- Name: t_entity_rename_log; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_entity_rename_log (
    entry_id integer NOT NULL,
    target_type integer NOT NULL,
    target_id integer NOT NULL,
    old_name public.citext,
    new_name public.citext,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE public.t_entity_rename_log OWNER TO d3l243;

--
-- Name: t_entity_rename_log_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_entity_rename_log ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_entity_rename_log_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_entity_rename_log pk_t_entity_rename_log; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_entity_rename_log
    ADD CONSTRAINT pk_t_entity_rename_log PRIMARY KEY (entry_id);

--
-- Name: ix_t_entity_rename_log_target_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_entity_rename_log_target_id ON public.t_entity_rename_log USING btree (target_id);

--
-- Name: ix_t_entity_rename_log_target_type; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_entity_rename_log_target_type ON public.t_entity_rename_log USING btree (target_type);

--
-- Name: t_entity_rename_log fk_t_entity_rename_log_t_event_target; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_entity_rename_log
    ADD CONSTRAINT fk_t_entity_rename_log_t_event_target FOREIGN KEY (target_type) REFERENCES public.t_event_target(target_type_id);

--
-- Name: TABLE t_entity_rename_log; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_entity_rename_log TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_entity_rename_log TO writeaccess;

