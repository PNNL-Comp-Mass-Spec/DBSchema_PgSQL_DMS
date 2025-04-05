--
-- Name: t_data_analysis_request_updates; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_data_analysis_request_updates (
    id integer NOT NULL,
    request_id integer NOT NULL,
    old_state_id smallint NOT NULL,
    new_state_id smallint NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entered_by public.citext NOT NULL
);


ALTER TABLE public.t_data_analysis_request_updates OWNER TO d3l243;

--
-- Name: t_data_analysis_request_updates_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_data_analysis_request_updates ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_data_analysis_request_updates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_data_analysis_request_updates pk_t_data_analysis_request_updates; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_data_analysis_request_updates
    ADD CONSTRAINT pk_t_data_analysis_request_updates PRIMARY KEY (id);

ALTER TABLE public.t_data_analysis_request_updates CLUSTER ON pk_t_data_analysis_request_updates;

--
-- Name: ix_t_data_analysis_request_updates_new_state_old_state_include; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_data_analysis_request_updates_new_state_old_state_include ON public.t_data_analysis_request_updates USING btree (new_state_id, old_state_id) INCLUDE (request_id, entered);

--
-- Name: ix_t_data_analysis_request_updates_request_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_data_analysis_request_updates_request_id ON public.t_data_analysis_request_updates USING btree (request_id);

--
-- Name: t_data_analysis_request_updates fk_t_data_analysis_request_updates_t_data_analysis_request1; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_data_analysis_request_updates
    ADD CONSTRAINT fk_t_data_analysis_request_updates_t_data_analysis_request1 FOREIGN KEY (new_state_id) REFERENCES public.t_data_analysis_request_state_name(state_id);

--
-- Name: t_data_analysis_request_updates fk_t_data_analysis_request_updates_t_data_analysis_request2; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_data_analysis_request_updates
    ADD CONSTRAINT fk_t_data_analysis_request_updates_t_data_analysis_request2 FOREIGN KEY (old_state_id) REFERENCES public.t_data_analysis_request_state_name(state_id);

--
-- Name: TABLE t_data_analysis_request_updates; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_data_analysis_request_updates TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_data_analysis_request_updates TO writeaccess;

