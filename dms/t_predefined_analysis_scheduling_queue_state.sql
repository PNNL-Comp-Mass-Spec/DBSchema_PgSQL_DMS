--
-- Name: t_predefined_analysis_scheduling_queue_state; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_predefined_analysis_scheduling_queue_state (
    state public.citext NOT NULL
);


ALTER TABLE public.t_predefined_analysis_scheduling_queue_state OWNER TO d3l243;

--
-- Name: t_predefined_analysis_scheduling_queue_state pk_t_predefined_analysis_scheduling_queue_state; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_predefined_analysis_scheduling_queue_state
    ADD CONSTRAINT pk_t_predefined_analysis_scheduling_queue_state PRIMARY KEY (state);

--
-- Name: TABLE t_predefined_analysis_scheduling_queue_state; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_predefined_analysis_scheduling_queue_state TO readaccess;

