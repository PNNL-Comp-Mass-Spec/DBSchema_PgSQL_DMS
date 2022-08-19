--
-- Name: v_processor_step_tools_list_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_processor_step_tools_list_report AS
 SELECT lp.processor_name,
    t_processor_tool.tool_name,
    t_processor_tool.priority,
    t_processor_tool.enabled,
    t_processor_tool.comment,
    lp.state AS processor_state,
    m.machine,
    m.total_cpus,
    m.bionet_available,
    lp.latest_request
   FROM (cap.t_machines m
     RIGHT JOIN ((cap.t_processor_tool
     JOIN cap.t_step_tools st ON ((t_processor_tool.tool_name OPERATOR(public.=) st.step_tool)))
     LEFT JOIN cap.t_local_processors lp ON ((t_processor_tool.processor_name OPERATOR(public.=) lp.processor_name))) ON ((m.machine OPERATOR(public.=) lp.machine)))
  WHERE (m.enabled > 0);


ALTER TABLE cap.v_processor_step_tools_list_report OWNER TO d3l243;

--
-- Name: TABLE v_processor_step_tools_list_report; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_processor_step_tools_list_report TO readaccess;

