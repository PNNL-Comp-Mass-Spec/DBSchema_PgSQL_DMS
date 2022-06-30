--
-- Name: v_capture_step_tools_detail_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_step_tools_detail_report AS
 SELECT t_step_tools.step_tool_id AS id,
    t_step_tools.step_tool,
    t_step_tools.description,
    t_step_tools.bionet_required,
    t_step_tools.only_on_storage_server,
    t_step_tools.instrument_capacity_limited,
    t_step_tools.holdoff_interval_minutes,
    t_step_tools.number_of_retries
   FROM cap.t_step_tools;


ALTER TABLE cap.v_capture_step_tools_detail_report OWNER TO d3l243;

