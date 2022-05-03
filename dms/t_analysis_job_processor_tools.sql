--
-- Name: t_analysis_job_processor_tools; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_processor_tools (
    tool_id integer NOT NULL,
    processor_id integer NOT NULL,
    entered timestamp without time zone,
    entered_by public.citext
);


ALTER TABLE public.t_analysis_job_processor_tools OWNER TO d3l243;

--
-- Name: t_analysis_job_processor_tools pk_t_analysis_job_processor_tools; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_processor_tools
    ADD CONSTRAINT pk_t_analysis_job_processor_tools PRIMARY KEY (tool_id, processor_id);

--
-- Name: TABLE t_analysis_job_processor_tools; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_processor_tools TO readaccess;

