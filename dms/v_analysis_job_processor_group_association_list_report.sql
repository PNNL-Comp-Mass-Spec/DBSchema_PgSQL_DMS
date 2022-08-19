--
-- Name: v_analysis_job_processor_group_association_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_processor_group_association_list_report AS
 SELECT ajpga.job,
    js.job_state AS state,
    ds.dataset,
    tool.analysis_tool AS tool,
    j.param_file_name AS param_file,
    j.settings_file_name AS settings_file,
    ajpga.group_id AS "#GroupID"
   FROM ((((public.t_analysis_job_processor_group_associations ajpga
     JOIN public.t_analysis_job j ON ((ajpga.job = j.job)))
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id)))
     JOIN public.t_analysis_job_state js ON ((j.job_state_id = js.job_state_id)))
  WHERE (j.job_state_id = ANY (ARRAY[1, 2, 3, 8, 9, 10, 11, 16, 17]));


ALTER TABLE public.v_analysis_job_processor_group_association_list_report OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_processor_group_association_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_processor_group_association_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_processor_group_association_list_report TO writeaccess;

