--
-- Name: v_capture_step_tools_entry; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_step_tools_entry AS
 SELECT t_step_tools.step_tool_id AS id,
    t_step_tools.step_tool,
    t_step_tools.description,
    t_step_tools.bionet_required,
    t_step_tools.only_on_storage_server,
    t_step_tools.instrument_capacity_limited
   FROM cap.t_step_tools;


ALTER TABLE cap.v_capture_step_tools_entry OWNER TO d3l243;

--
-- Name: TABLE v_capture_step_tools_entry; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_step_tools_entry TO readaccess;
GRANT SELECT ON TABLE cap.v_capture_step_tools_entry TO writeaccess;

