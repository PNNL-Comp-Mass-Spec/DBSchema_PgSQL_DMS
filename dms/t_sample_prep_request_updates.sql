--
-- Name: t_sample_prep_request_updates; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_sample_prep_request_updates (
    entry_id integer NOT NULL,
    request_id integer NOT NULL,
    system_account public.citext NOT NULL,
    date_of_change timestamp without time zone NOT NULL,
    beginning_state_id smallint NOT NULL,
    end_state_id smallint NOT NULL
);


ALTER TABLE public.t_sample_prep_request_updates OWNER TO d3l243;

--
-- Name: t_sample_prep_request_updates_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_sample_prep_request_updates ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_sample_prep_request_updates_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_sample_prep_request_updates pk_t_sample_prep_request_updates; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_prep_request_updates
    ADD CONSTRAINT pk_t_sample_prep_request_updates PRIMARY KEY (entry_id);

--
-- Name: ix_t_sample_prep_request_updates_end_state_id_begin_state_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_sample_prep_request_updates_end_state_id_begin_state_id ON public.t_sample_prep_request_updates USING btree (end_state_id, beginning_state_id) INCLUDE (request_id, date_of_change);

--
-- Name: ix_t_sample_prep_request_updates_request_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_sample_prep_request_updates_request_id ON public.t_sample_prep_request_updates USING btree (request_id);

--
-- Name: t_sample_prep_request_updates fk_t_sample_prep_request_updates_t_sample_prep_request_state1; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_prep_request_updates
    ADD CONSTRAINT fk_t_sample_prep_request_updates_t_sample_prep_request_state1 FOREIGN KEY (beginning_state_id) REFERENCES public.t_sample_prep_request_state_name(state_id);

--
-- Name: t_sample_prep_request_updates fk_t_sample_prep_request_updates_t_sample_prep_request_state2; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_prep_request_updates
    ADD CONSTRAINT fk_t_sample_prep_request_updates_t_sample_prep_request_state2 FOREIGN KEY (end_state_id) REFERENCES public.t_sample_prep_request_state_name(state_id);

--
-- Name: TABLE t_sample_prep_request_updates; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_sample_prep_request_updates TO readaccess;

