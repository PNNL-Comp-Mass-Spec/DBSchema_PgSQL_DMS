--
-- Name: t_analysis_job_state; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_state (
    job_state_id integer NOT NULL,
    job_state public.citext NOT NULL,
    comment public.citext
);


ALTER TABLE public.t_analysis_job_state OWNER TO d3l243;

--
-- Name: t_analysis_job_state pk_t_analysis_job_state; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_state
    ADD CONSTRAINT pk_t_analysis_job_state PRIMARY KEY (job_state_id);

--
-- Name: TABLE t_analysis_job_state; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_state TO readaccess;

