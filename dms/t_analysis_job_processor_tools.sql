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
-- Name: TABLE t_analysis_job_processor_tools; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_processor_tools TO readaccess;

