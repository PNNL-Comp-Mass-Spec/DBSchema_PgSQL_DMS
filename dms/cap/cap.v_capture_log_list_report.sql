--
-- Name: v_capture_log_list_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_log_list_report AS
 SELECT t_log_entries.entry_id AS id,
    t_log_entries.posted_by,
    t_log_entries.entered AS "time",
    t_log_entries.type,
    t_log_entries.message,
    t_log_entries.entered_by
   FROM cap.t_log_entries;


ALTER VIEW cap.v_capture_log_list_report OWNER TO d3l243;

--
-- Name: TABLE v_capture_log_list_report; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_log_list_report TO readaccess;
GRANT SELECT ON TABLE cap.v_capture_log_list_report TO writeaccess;

