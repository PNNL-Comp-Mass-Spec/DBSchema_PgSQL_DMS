--
-- Name: v_capture_step_tools_detail_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_step_tools_detail_report AS
 SELECT step_tool_id AS id,
    step_tool AS name,
    description,
    bionet_required,
    only_on_storage_server,
    instrument_capacity_limited,
    holdoff_interval_minutes,
    number_of_retries
   FROM cap.t_step_tools;


ALTER VIEW cap.v_capture_step_tools_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_capture_step_tools_detail_report; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_step_tools_detail_report TO readaccess;
GRANT SELECT ON TABLE cap.v_capture_step_tools_detail_report TO writeaccess;

