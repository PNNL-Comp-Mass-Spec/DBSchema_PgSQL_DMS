--
-- Name: v_pipeline_step_tool_storage_paths; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_step_tool_storage_paths AS
 SELECT step_tool_id,
    step_tool,
    type,
    description,
    COALESCE(param_file_storage_path, ''::public.citext) AS param_file_storage_path
   FROM sw.t_step_tools;


ALTER VIEW sw.v_pipeline_step_tool_storage_paths OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_step_tool_storage_paths; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_step_tool_storage_paths TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_step_tool_storage_paths TO writeaccess;

