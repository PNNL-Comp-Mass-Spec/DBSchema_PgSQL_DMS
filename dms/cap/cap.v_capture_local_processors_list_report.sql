--
-- Name: v_capture_local_processors_list_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_local_processors_list_report AS
 SELECT t_local_processors.processor_name,
    t_local_processors.state,
    t_local_processors.machine,
    t_local_processors.manager_version,
    cap.get_processor_step_tool_list(t_local_processors.processor_name) AS tools,
    cap.get_processor_assigned_instrument_list(t_local_processors.processor_name) AS instruments,
    t_local_processors.latest_request
   FROM cap.t_local_processors;


ALTER TABLE cap.v_capture_local_processors_list_report OWNER TO d3l243;

--
-- Name: TABLE v_capture_local_processors_list_report; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_local_processors_list_report TO readaccess;
GRANT SELECT ON TABLE cap.v_capture_local_processors_list_report TO writeaccess;

