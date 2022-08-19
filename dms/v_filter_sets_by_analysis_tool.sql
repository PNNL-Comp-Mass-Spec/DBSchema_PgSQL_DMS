--
-- Name: v_filter_sets_by_analysis_tool; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_filter_sets_by_analysis_tool AS
 SELECT fs.filter_set_id,
    public.min(fs.filter_set_name) AS filter_set_name,
    public.min(fs.filter_set_description) AS filter_set_description,
    fscm.analysis_tool_id,
    tool.analysis_tool AS analysis_tool_name
   FROM (((public.t_filter_set_criteria_groups fscg
     JOIN public.t_filter_sets fs ON ((fscg.filter_set_id = fs.filter_set_id)))
     JOIN public.t_filter_set_criteria fsc ON ((fscg.filter_criteria_group_id = fsc.filter_criteria_group_id)))
     JOIN (public.t_filter_set_criteria_name_tool_map fscm
     JOIN public.t_analysis_tool tool ON ((fscm.analysis_tool_id = tool.analysis_tool_id))) ON ((fsc.criterion_id = fscm.criterion_id)))
  GROUP BY fscm.analysis_tool_id, fs.filter_set_id, tool.analysis_tool;


ALTER TABLE public.v_filter_sets_by_analysis_tool OWNER TO d3l243;

--
-- Name: TABLE v_filter_sets_by_analysis_tool; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_filter_sets_by_analysis_tool TO readaccess;
GRANT SELECT ON TABLE public.v_filter_sets_by_analysis_tool TO writeaccess;

