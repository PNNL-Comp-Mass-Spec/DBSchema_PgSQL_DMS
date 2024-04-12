--
-- Name: v_analysis_tool_paths; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_tool_paths AS
 SELECT analysis_tool_id,
    analysis_tool AS tool_name,
    tool_base_name,
    param_file_storage_path,
    param_file_storage_path_local,
    result_type,
    active AS tool_active
   FROM public.t_analysis_tool t
  WHERE (analysis_tool_id > 0);


ALTER VIEW public.v_analysis_tool_paths OWNER TO d3l243;

--
-- Name: TABLE v_analysis_tool_paths; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_tool_paths TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_tool_paths TO writeaccess;

