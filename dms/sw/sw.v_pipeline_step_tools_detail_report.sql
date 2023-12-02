--
-- Name: v_pipeline_step_tools_detail_report; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_step_tools_detail_report AS
 SELECT t_step_tools.step_tool_id AS id,
    t_step_tools.step_tool AS name,
    t_step_tools.type,
    t_step_tools.description,
    t_step_tools.comment,
    t_step_tools.shared_result_version,
    t_step_tools.filter_version,
    t_step_tools.cpu_load,
    t_step_tools.uses_all_cores,
    t_step_tools.memory_usage_mb,
    t_step_tools.available_for_general_processing,
    t_step_tools.param_file_storage_path,
    t_step_tools.parameter_template,
    t_step_tools.tag,
    t_step_tools.avg_runtime_minutes,
    t_step_tools.disable_output_folder_name_override_on_skip,
    t_step_tools.primary_step_tool,
    t_step_tools.holdoff_interval_minutes
   FROM sw.t_step_tools;


ALTER VIEW sw.v_pipeline_step_tools_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_step_tools_detail_report; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_step_tools_detail_report TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_step_tools_detail_report TO writeaccess;

