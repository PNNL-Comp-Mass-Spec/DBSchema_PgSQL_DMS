--
-- Name: v_processor_tool_for_manager; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_processor_tool_for_manager AS
 SELECT processor_name AS mgr_name,
    tool_name AS tool,
    enabled AS enabled_short
   FROM cap.t_processor_tool;


ALTER VIEW cap.v_processor_tool_for_manager OWNER TO d3l243;

--
-- Name: TABLE v_processor_tool_for_manager; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_processor_tool_for_manager TO readaccess;
GRANT SELECT ON TABLE cap.v_processor_tool_for_manager TO writeaccess;

