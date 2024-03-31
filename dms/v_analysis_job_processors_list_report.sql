--
-- Name: v_analysis_job_processors_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_processors_list_report AS
 SELECT processor_id AS id,
    state,
    processor_name AS name,
    machine,
    (public.get_aj_processor_analysis_tool_list(processor_id))::public.citext AS analysis_tools,
    notes,
    (public.get_aj_processor_membership_in_groups_list(processor_id, 1))::public.citext AS enabled_groups,
    (public.get_aj_processor_membership_in_groups_list(processor_id, 0))::public.citext AS disabled_groups
   FROM public.t_analysis_job_processors;


ALTER VIEW public.v_analysis_job_processors_list_report OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_processors_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_processors_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_processors_list_report TO writeaccess;

