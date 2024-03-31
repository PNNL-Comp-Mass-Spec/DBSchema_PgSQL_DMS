--
-- Name: v_pipeline_step_tools_list_report; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_step_tools_list_report AS
 SELECT step_tool AS name,
    type,
    description,
    shared_result_version,
    filter_version,
    cpu_load,
    memory_usage_mb,
    step_tool_id AS id
   FROM sw.t_step_tools;


ALTER VIEW sw.v_pipeline_step_tools_list_report OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_step_tools_list_report; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_step_tools_list_report TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_step_tools_list_report TO writeaccess;

