--
-- Name: v_pipeline_step_tools_entry; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_step_tools_entry AS
 SELECT step_tool_id AS id,
    step_tool AS name,
    type,
    description,
    shared_result_version,
    filter_version,
    cpu_load,
    memory_usage_mb,
    parameter_template,
    param_file_storage_path
   FROM sw.t_step_tools;


ALTER VIEW sw.v_pipeline_step_tools_entry OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_step_tools_entry; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_step_tools_entry TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_step_tools_entry TO writeaccess;

