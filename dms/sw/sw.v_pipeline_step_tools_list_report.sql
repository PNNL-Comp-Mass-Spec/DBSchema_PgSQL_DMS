--
-- Name: v_pipeline_step_tools_list_report; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_step_tools_list_report AS
 SELECT t_step_tools.step_tool AS name,
    t_step_tools.type,
    t_step_tools.description,
    t_step_tools.shared_result_version,
    t_step_tools.filter_version,
    t_step_tools.cpu_load,
    t_step_tools.memory_usage_mb,
    t_step_tools.step_tool_id AS id
   FROM sw.t_step_tools;


ALTER TABLE sw.v_pipeline_step_tools_list_report OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_step_tools_list_report; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_step_tools_list_report TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_step_tools_list_report TO writeaccess;

