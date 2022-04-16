--
-- Name: t_requested_run_state_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_requested_run_state_name (
    state_name public.citext NOT NULL,
    state_id smallint NOT NULL
);


ALTER TABLE public.t_requested_run_state_name OWNER TO d3l243;

--
-- Name: TABLE t_requested_run_state_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_requested_run_state_name TO readaccess;

