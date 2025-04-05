--
-- Name: t_analysis_job_request_existing_jobs; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_request_existing_jobs (
    request_id integer NOT NULL,
    job integer NOT NULL
);


ALTER TABLE public.t_analysis_job_request_existing_jobs OWNER TO d3l243;

--
-- Name: t_analysis_job_request_existing_jobs pk_t_analysis_job_request_existing_jobs; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_request_existing_jobs
    ADD CONSTRAINT pk_t_analysis_job_request_existing_jobs PRIMARY KEY (request_id, job);

ALTER TABLE public.t_analysis_job_request_existing_jobs CLUSTER ON pk_t_analysis_job_request_existing_jobs;

--
-- Name: TABLE t_analysis_job_request_existing_jobs; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_request_existing_jobs TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_analysis_job_request_existing_jobs TO writeaccess;

