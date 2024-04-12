--
-- Name: v_historic_log_report; Type: VIEW; Schema: logdms; Owner: d3l243
--

CREATE VIEW logdms.v_historic_log_report AS
 SELECT entry_id AS entry,
    posted_by,
    entered,
    type,
    message
   FROM logdms.t_log_entries;


ALTER VIEW logdms.v_historic_log_report OWNER TO d3l243;

--
-- Name: TABLE v_historic_log_report; Type: ACL; Schema: logdms; Owner: d3l243
--

GRANT SELECT ON TABLE logdms.v_historic_log_report TO writeaccess;

