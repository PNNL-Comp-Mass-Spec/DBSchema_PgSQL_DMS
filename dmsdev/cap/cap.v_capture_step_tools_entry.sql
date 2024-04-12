--
-- Name: v_capture_step_tools_entry; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_step_tools_entry AS
 SELECT step_tool_id AS id,
    step_tool AS name,
    description,
    bionet_required,
    only_on_storage_server,
    instrument_capacity_limited
   FROM cap.t_step_tools;


ALTER VIEW cap.v_capture_step_tools_entry OWNER TO d3l243;

--
-- Name: TABLE v_capture_step_tools_entry; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_step_tools_entry TO readaccess;
GRANT SELECT ON TABLE cap.v_capture_step_tools_entry TO writeaccess;

