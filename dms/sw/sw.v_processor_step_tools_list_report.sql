--
-- Name: v_processor_step_tools_list_report; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_processor_step_tools_list_report AS
 SELECT lp.processor_name,
    ptgd.tool_name,
    ptgd.priority,
    ptgd.enabled,
    ptgd.comment,
    st.cpu_load AS tool_cpu_load,
    lp.latest_request,
    lp.manager_version,
    lp.processor_id AS proc_id,
    lp.state AS processor_state,
    m.machine,
    m.total_cpus,
    m.cpus_available,
    m.total_memory_mb,
    m.memory_available,
    m.comment AS machine_comment,
    ptg.group_id,
    ptg.group_name,
    ptg.enabled AS group_enabled
   FROM ((((sw.t_machines m
     JOIN sw.t_local_processors lp ON ((m.machine OPERATOR(public.=) lp.machine)))
     JOIN sw.t_processor_tool_groups ptg ON ((m.proc_tool_group_id = ptg.group_id)))
     JOIN sw.t_processor_tool_group_details ptgd ON (((ptg.group_id = ptgd.group_id) AND (lp.proc_tool_mgr_id = ptgd.mgr_id))))
     JOIN sw.t_step_tools st ON ((ptgd.tool_name OPERATOR(public.=) st.step_tool)))
  WHERE (m.enabled > 0);


ALTER TABLE sw.v_processor_step_tools_list_report OWNER TO d3l243;

--
-- Name: TABLE v_processor_step_tools_list_report; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_processor_step_tools_list_report TO readaccess;
GRANT SELECT ON TABLE sw.v_processor_step_tools_list_report TO writeaccess;

