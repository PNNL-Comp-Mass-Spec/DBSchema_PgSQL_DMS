--
-- Name: v_pipeline_step_tools_detail_report; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_step_tools_detail_report AS
 SELECT step_tool_id AS id,
    step_tool AS name,
    type,
    description,
    comment,
    shared_result_version,
    filter_version,
    cpu_load,
    uses_all_cores,
    memory_usage_mb,
    available_for_general_processing,
    param_file_storage_path,
    public.xml_to_html(parameter_template) AS parameter_template,
    tag,
    avg_runtime_minutes,
    disable_output_folder_name_override_on_skip,
    primary_step_tool,
    holdoff_interval_minutes
   FROM sw.t_step_tools;


ALTER VIEW sw.v_pipeline_step_tools_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_step_tools_detail_report; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_step_tools_detail_report TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_step_tools_detail_report TO writeaccess;

