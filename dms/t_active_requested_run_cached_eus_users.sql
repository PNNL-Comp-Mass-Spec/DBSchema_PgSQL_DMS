--
-- Name: t_active_requested_run_cached_eus_users; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_active_requested_run_cached_eus_users (
    request_id integer NOT NULL,
    user_list public.citext
);


ALTER TABLE public.t_active_requested_run_cached_eus_users OWNER TO d3l243;

--
-- Name: t_active_requested_run_cached_eus_users pk_t_active_requested_run_cached_eus_users; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_active_requested_run_cached_eus_users
    ADD CONSTRAINT pk_t_active_requested_run_cached_eus_users PRIMARY KEY (request_id);

--
-- Name: t_active_requested_run_cached_eus_users fk_t_active_requested_run_cached_eus_users_t_requested_run; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_active_requested_run_cached_eus_users
    ADD CONSTRAINT fk_t_active_requested_run_cached_eus_users_t_requested_run FOREIGN KEY (request_id) REFERENCES public.t_requested_run(request_id) ON DELETE CASCADE;

--
-- Name: TABLE t_active_requested_run_cached_eus_users; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_active_requested_run_cached_eus_users TO readaccess;

