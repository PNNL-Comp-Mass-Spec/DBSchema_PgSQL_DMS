--
-- Name: t_requested_run_eus_users; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_requested_run_eus_users (
    eus_person_id integer NOT NULL,
    request_id integer NOT NULL
);


ALTER TABLE public.t_requested_run_eus_users OWNER TO d3l243;

--
-- Name: t_requested_run_eus_users pk_t_requested_run_eus_users; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run_eus_users
    ADD CONSTRAINT pk_t_requested_run_eus_users PRIMARY KEY (eus_person_id, request_id);

--
-- Name: ix_t_requested_run_eus_users_request_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_eus_users_request_id ON public.t_requested_run_eus_users USING btree (request_id);

--
-- Name: t_requested_run_eus_users fk_t_requested_run_eus_users_t_eus_users; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run_eus_users
    ADD CONSTRAINT fk_t_requested_run_eus_users_t_eus_users FOREIGN KEY (eus_person_id) REFERENCES public.t_eus_users(person_id);

--
-- Name: t_requested_run_eus_users fk_t_requested_run_eus_users_t_requested_run; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run_eus_users
    ADD CONSTRAINT fk_t_requested_run_eus_users_t_requested_run FOREIGN KEY (request_id) REFERENCES public.t_requested_run(request_id) ON DELETE CASCADE;

--
-- Name: TABLE t_requested_run_eus_users; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_requested_run_eus_users TO readaccess;

