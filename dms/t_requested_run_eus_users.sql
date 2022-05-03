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
-- Name: TABLE t_requested_run_eus_users; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_requested_run_eus_users TO readaccess;

