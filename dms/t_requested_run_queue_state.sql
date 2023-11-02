--
-- Name: t_requested_run_queue_state; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_requested_run_queue_state (
    queue_state smallint NOT NULL,
    queue_state_name public.citext NOT NULL
);


ALTER TABLE public.t_requested_run_queue_state OWNER TO d3l243;

--
-- Name: t_requested_run_queue_state pk_t_requested_run_queue_state; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run_queue_state
    ADD CONSTRAINT pk_t_requested_run_queue_state PRIMARY KEY (queue_state);

ALTER TABLE public.t_requested_run_queue_state CLUSTER ON pk_t_requested_run_queue_state;

--
-- Name: TABLE t_requested_run_queue_state; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_requested_run_queue_state TO readaccess;
GRANT SELECT ON TABLE public.t_requested_run_queue_state TO writeaccess;

