--
-- Name: v_filter_set_criteria_name_owners; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_filter_set_criteria_name_owners AS
 SELECT t_filter_set_criteria_names.criterion_id,
    t_filter_set_criteria_names.criterion_name,
    t_filter_set_criteria_names.criterion_description,
    t_filter_set_criteria_name_tool_map.analysis_tool_id,
    t_analysis_tool.analysis_tool AS analysis_tool_name
   FROM ((public.t_filter_set_criteria_names
     JOIN public.t_filter_set_criteria_name_tool_map ON ((t_filter_set_criteria_names.criterion_id = t_filter_set_criteria_name_tool_map.criterion_id)))
     JOIN public.t_analysis_tool ON ((t_filter_set_criteria_name_tool_map.analysis_tool_id = t_analysis_tool.analysis_tool_id)));


ALTER TABLE public.v_filter_set_criteria_name_owners OWNER TO d3l243;

--
-- Name: TABLE v_filter_set_criteria_name_owners; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_filter_set_criteria_name_owners TO readaccess;
GRANT SELECT ON TABLE public.v_filter_set_criteria_name_owners TO writeaccess;

