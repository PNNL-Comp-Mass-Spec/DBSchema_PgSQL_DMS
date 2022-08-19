--
-- Name: v_historic_log_report; Type: VIEW; Schema: logdms; Owner: d3l243
--

CREATE VIEW logdms.v_historic_log_report AS
 SELECT t_log_entries.entry_id AS entry,
    t_log_entries.posted_by,
    t_log_entries.posting_time,
    t_log_entries.type,
    t_log_entries.message
   FROM logdms.t_log_entries;


ALTER TABLE logdms.v_historic_log_report OWNER TO d3l243;

--
-- Name: TABLE v_historic_log_report; Type: ACL; Schema: logdms; Owner: d3l243
--

GRANT SELECT ON TABLE logdms.v_historic_log_report TO writeaccess;

