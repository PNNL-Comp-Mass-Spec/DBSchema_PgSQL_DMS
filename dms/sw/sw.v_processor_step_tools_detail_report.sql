--
-- Name: v_processor_step_tools_detail_report; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_processor_step_tools_detail_report AS
 SELECT lp.processor_name,
    lp.processor_id,
    lp.state AS processor_state,
    m.machine,
    lp.latest_request,
    lp.manager_version,
    sw.get_processor_step_tool_list((lp.processor_name)::text) AS enabled_tools,
    sw.get_disabled_processor_step_tool_list((lp.processor_name)::text) AS disabled_tools,
    m.total_cpus,
    m.cpus_available,
    m.total_memory_mb,
    m.memory_available,
    m.comment AS machine_comment,
    lp.work_dir_admin_share
   FROM (sw.t_machines m
     JOIN sw.t_local_processors lp ON ((m.machine OPERATOR(public.=) lp.machine)));


ALTER VIEW sw.v_processor_step_tools_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_processor_step_tools_detail_report; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_processor_step_tools_detail_report TO readaccess;
GRANT SELECT ON TABLE sw.v_processor_step_tools_detail_report TO writeaccess;

