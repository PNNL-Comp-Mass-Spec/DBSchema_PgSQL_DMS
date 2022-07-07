--
-- Name: v_analysis_tool_paths; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_tool_paths AS
 SELECT t_analysis_tool.analysis_tool AS tool_name,
    t_analysis_tool.param_file_storage_path_local AS param_dir,
    ((t_analysis_tool.param_file_storage_path_local)::text || 'SettingsFiles\'::text) AS settings_dir
   FROM public.t_analysis_tool
  WHERE (t_analysis_tool.analysis_tool_id > 0);


ALTER TABLE public.v_analysis_tool_paths OWNER TO d3l243;

--
-- Name: TABLE v_analysis_tool_paths; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_tool_paths TO readaccess;

