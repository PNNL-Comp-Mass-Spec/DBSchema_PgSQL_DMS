--
-- Name: v_processor_tool_group_details; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_processor_tool_group_details AS
 SELECT ptg.group_id,
    ptg.group_name,
    ptg.enabled AS group_enabled,
    ptg.comment AS group_comment,
    ptgd.mgr_id,
    ptgd.tool_name,
    ptgd.priority,
    ptgd.enabled,
    ptgd.comment,
    ptgd.max_job_priority,
    ptgd.last_affected
   FROM (sw.t_processor_tool_group_details ptgd
     JOIN sw.t_processor_tool_groups ptg ON ((ptgd.group_id = ptg.group_id)))
  WHERE (ptg.enabled > '-10'::integer);


ALTER VIEW sw.v_processor_tool_group_details OWNER TO d3l243;

--
-- Name: TABLE v_processor_tool_group_details; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_processor_tool_group_details TO readaccess;
GRANT SELECT ON TABLE sw.v_processor_tool_group_details TO writeaccess;

