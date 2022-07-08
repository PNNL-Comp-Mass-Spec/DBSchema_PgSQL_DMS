--
-- Name: v_capture_machines_list_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_machines_list_report AS
 SELECT t_machines.machine,
    t_machines.bionet_available
   FROM cap.t_machines;


ALTER TABLE cap.v_capture_machines_list_report OWNER TO d3l243;
