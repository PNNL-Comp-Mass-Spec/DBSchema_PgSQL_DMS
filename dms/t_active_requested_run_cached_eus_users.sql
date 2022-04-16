--
-- Name: t_active_requested_run_cached_eus_users; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_active_requested_run_cached_eus_users (
    request_id integer NOT NULL,
    user_list public.citext
);


ALTER TABLE public.t_active_requested_run_cached_eus_users OWNER TO d3l243;

--
-- Name: TABLE t_active_requested_run_cached_eus_users; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_active_requested_run_cached_eus_users TO readaccess;

