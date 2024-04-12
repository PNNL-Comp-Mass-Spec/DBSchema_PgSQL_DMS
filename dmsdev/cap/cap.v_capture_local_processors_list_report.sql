--
-- Name: v_capture_local_processors_list_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_local_processors_list_report AS
 SELECT processor_name,
    state,
    machine,
    manager_version,
    (cap.get_ctm_processor_step_tool_list((processor_name)::text))::public.citext AS tools,
    (cap.get_ctm_processor_assigned_instrument_list((processor_name)::text))::public.citext AS instruments,
    latest_request
   FROM cap.t_local_processors;


ALTER VIEW cap.v_capture_local_processors_list_report OWNER TO d3l243;

--
-- Name: TABLE v_capture_local_processors_list_report; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_local_processors_list_report TO readaccess;
GRANT SELECT ON TABLE cap.v_capture_local_processors_list_report TO writeaccess;

