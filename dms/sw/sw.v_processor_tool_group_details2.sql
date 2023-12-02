--
-- Name: v_processor_tool_group_details2; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_processor_tool_group_details2 AS
 SELECT ptgd.group_id,
    ptgd.group_name,
    ptgd.group_enabled,
    ptgd.group_comment,
    ptgd.mgr_id,
    ptgd.tool_name,
    ptgd.priority,
    ptgd.enabled,
    ptgd.comment,
    ptgd.max_job_priority,
    ptgd.last_affected,
    m.machine,
    lp.processor_name AS processor
   FROM ((sw.t_local_processors lp
     JOIN sw.t_machines m ON ((lp.machine OPERATOR(public.=) m.machine)))
     JOIN sw.v_processor_tool_group_details ptgd ON (((m.proc_tool_group_id = ptgd.group_id) AND (lp.proc_tool_mgr_id = ptgd.mgr_id))));


ALTER VIEW sw.v_processor_tool_group_details2 OWNER TO d3l243;

--
-- Name: TABLE v_processor_tool_group_details2; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_processor_tool_group_details2 TO readaccess;
GRANT SELECT ON TABLE sw.v_processor_tool_group_details2 TO writeaccess;

