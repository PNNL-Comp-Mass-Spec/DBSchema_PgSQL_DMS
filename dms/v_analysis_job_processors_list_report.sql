--
-- Name: v_analysis_job_processors_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_processors_list_report AS
 SELECT t_analysis_job_processors.processor_id AS id,
    t_analysis_job_processors.state,
    t_analysis_job_processors.processor_name AS name,
    t_analysis_job_processors.machine,
    public.get_aj_processor_analysis_tool_list(t_analysis_job_processors.processor_id) AS analysis_tools,
    t_analysis_job_processors.notes,
    public.get_aj_processor_membership_in_groups_list(t_analysis_job_processors.processor_id, 1) AS enabled_groups,
    public.get_aj_processor_membership_in_groups_list(t_analysis_job_processors.processor_id, 0) AS disabled_groups
   FROM public.t_analysis_job_processors;


ALTER TABLE public.v_analysis_job_processors_list_report OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_processors_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_processors_list_report TO readaccess;

