--
-- Name: t_analysis_job_processor_tools; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_processor_tools (
    tool_id integer NOT NULL,
    processor_id integer NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE public.t_analysis_job_processor_tools OWNER TO d3l243;

--
-- Name: t_analysis_job_processor_tools pk_t_analysis_job_processor_tools; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_processor_tools
    ADD CONSTRAINT pk_t_analysis_job_processor_tools PRIMARY KEY (tool_id, processor_id);

ALTER TABLE public.t_analysis_job_processor_tools CLUSTER ON pk_t_analysis_job_processor_tools;

--
-- Name: t_analysis_job_processor_tools fk_t_analysis_job_processor_tools_t_analysis_job_processors; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_processor_tools
    ADD CONSTRAINT fk_t_analysis_job_processor_tools_t_analysis_job_processors FOREIGN KEY (processor_id) REFERENCES public.t_analysis_job_processors(processor_id);

--
-- Name: t_analysis_job_processor_tools fk_t_analysis_job_processor_tools_t_analysis_tool; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_processor_tools
    ADD CONSTRAINT fk_t_analysis_job_processor_tools_t_analysis_tool FOREIGN KEY (tool_id) REFERENCES public.t_analysis_tool(analysis_tool_id);

--
-- Name: TABLE t_analysis_job_processor_tools; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_processor_tools TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_analysis_job_processor_tools TO writeaccess;

