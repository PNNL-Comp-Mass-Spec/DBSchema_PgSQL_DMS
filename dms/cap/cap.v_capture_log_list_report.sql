--
-- Name: v_capture_log_list_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_log_list_report AS
 SELECT t_log_entries.entry_id AS id,
    t_log_entries.posted_by,
    t_log_entries.posting_time AS "time",
    t_log_entries.type,
    t_log_entries.message,
    t_log_entries.entered_by
   FROM cap.t_log_entries;


ALTER TABLE cap.v_capture_log_list_report OWNER TO d3l243;

