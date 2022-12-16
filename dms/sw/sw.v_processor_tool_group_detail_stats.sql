--
-- Name: v_processor_tool_group_detail_stats; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_processor_tool_group_detail_stats AS
 SELECT ptg.group_id,
    ptg.group_name,
    ptg.enabled AS group_enabled,
    ptg.comment,
    ptgd.tool_name,
    ptgd.priority,
    ptgd.enabled,
    count(*) AS managers
   FROM (((sw.t_machines m
     JOIN sw.t_local_processors lp ON ((m.machine OPERATOR(public.=) lp.machine)))
     JOIN sw.t_processor_tool_groups ptg ON ((m.proc_tool_group_id = ptg.group_id)))
     JOIN sw.t_processor_tool_group_details ptgd ON (((ptg.group_id = ptgd.group_id) AND (lp.proc_tool_mgr_id = ptgd.mgr_id))))
  WHERE (ptg.enabled > '-10'::integer)
  GROUP BY ptg.group_id, ptg.group_name, ptg.enabled, ptg.comment, ptgd.tool_name, ptgd.priority, ptgd.enabled;


ALTER TABLE sw.v_processor_tool_group_detail_stats OWNER TO d3l243;

--
-- Name: TABLE v_processor_tool_group_detail_stats; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_processor_tool_group_detail_stats TO readaccess;
GRANT SELECT ON TABLE sw.v_processor_tool_group_detail_stats TO writeaccess;

