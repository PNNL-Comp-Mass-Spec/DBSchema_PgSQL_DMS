--
-- Name: t_analysis_job_request_state; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_request_state (
    request_state_id integer NOT NULL,
    request_state public.citext NOT NULL
);


ALTER TABLE public.t_analysis_job_request_state OWNER TO d3l243;

--
-- Name: t_analysis_job_request_state pk_t_analysis_job_request_state; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_request_state
    ADD CONSTRAINT pk_t_analysis_job_request_state PRIMARY KEY (request_state_id);

--
-- Name: TABLE t_analysis_job_request_state; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_request_state TO readaccess;
GRANT SELECT ON TABLE public.t_analysis_job_request_state TO writeaccess;

