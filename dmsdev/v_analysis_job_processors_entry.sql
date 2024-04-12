--
-- Name: v_analysis_job_processors_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_processors_entry AS
 SELECT processor_id AS id,
    state,
    processor_name,
    machine,
    notes,
    public.get_aj_processor_analysis_tool_list(processor_id) AS analysis_tools_list
   FROM public.t_analysis_job_processors;


ALTER VIEW public.v_analysis_job_processors_entry OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_processors_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_processors_entry TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_processors_entry TO writeaccess;

