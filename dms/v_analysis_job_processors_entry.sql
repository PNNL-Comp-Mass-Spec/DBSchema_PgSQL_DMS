--
-- Name: v_analysis_job_processors_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_processors_entry AS
 SELECT t_analysis_job_processors.processor_id AS id,
    t_analysis_job_processors.state,
    t_analysis_job_processors.processor_name,
    t_analysis_job_processors.machine,
    t_analysis_job_processors.notes,
    public.get_aj_processor_analysis_tool_list(t_analysis_job_processors.processor_id) AS analysis_tools_list
   FROM public.t_analysis_job_processors;


ALTER TABLE public.v_analysis_job_processors_entry OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_processors_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_processors_entry TO readaccess;

