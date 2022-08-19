--
-- Name: v_param_file_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_param_file_list_report AS
 SELECT pf.param_file_id,
    pf.param_file_name,
    pft.param_file_type,
    pf.param_file_description,
    tool.analysis_tool AS primary_tool,
    pf.date_created,
    pf.date_modified,
    pf.job_usage_count,
    pf.job_usage_last_year,
    pf.valid,
    pf.mod_list
   FROM ((public.t_param_files pf
     JOIN public.t_param_file_types pft ON ((pf.param_file_type_id = pft.param_file_type_id)))
     JOIN public.t_analysis_tool tool ON ((pft.primary_tool_id = tool.analysis_tool_id)));


ALTER TABLE public.v_param_file_list_report OWNER TO d3l243;

--
-- Name: TABLE v_param_file_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_param_file_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_param_file_list_report TO writeaccess;

