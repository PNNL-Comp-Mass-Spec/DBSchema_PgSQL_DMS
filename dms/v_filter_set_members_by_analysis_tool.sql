--
-- Name: v_filter_set_members_by_analysis_tool; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_filter_set_members_by_analysis_tool AS
 SELECT fs.filter_type_id,
    fs.filter_type_name,
    fs.filter_set_id,
    fs.filter_set_name,
    fs.filter_set_description,
    fs.filter_criteria_group_id,
    fs.criterion_id,
    fs.criterion_name,
    fs.filter_set_criteria_id,
    fs.criterion_comparison,
    fs.criterion_value,
    fscm.analysis_tool_id,
    tool.analysis_tool AS analysis_tool_name
   FROM ((public.v_filter_sets fs
     JOIN public.t_filter_set_criteria_name_tool_map fscm ON ((fs.criterion_id = fscm.criterion_id)))
     JOIN public.t_analysis_tool tool ON ((fscm.analysis_tool_id = tool.analysis_tool_id)));


ALTER TABLE public.v_filter_set_members_by_analysis_tool OWNER TO d3l243;

--
-- Name: TABLE v_filter_set_members_by_analysis_tool; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_filter_set_members_by_analysis_tool TO readaccess;
GRANT SELECT ON TABLE public.v_filter_set_members_by_analysis_tool TO writeaccess;

