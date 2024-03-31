--
-- Name: v_capture_machines_list_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_machines_list_report AS
 SELECT machine,
    bionet_available
   FROM cap.t_machines;


ALTER VIEW cap.v_capture_machines_list_report OWNER TO d3l243;

--
-- Name: TABLE v_capture_machines_list_report; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_machines_list_report TO readaccess;
GRANT SELECT ON TABLE cap.v_capture_machines_list_report TO writeaccess;

