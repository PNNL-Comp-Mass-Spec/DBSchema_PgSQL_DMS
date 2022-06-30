--
-- Name: v_processor_tool_for_manager; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_processor_tool_for_manager AS
 SELECT t_processor_tool.processor_name AS mgr_name,
    t_processor_tool.tool_name AS tool,
    t_processor_tool.enabled AS enabled_short
   FROM cap.t_processor_tool;


ALTER TABLE cap.v_processor_tool_for_manager OWNER TO d3l243;

