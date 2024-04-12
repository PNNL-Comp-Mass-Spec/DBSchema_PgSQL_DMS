--
-- Name: v_chain_errors_summary; Type: VIEW; Schema: timetable; Owner: d3l243
--

CREATE VIEW timetable.v_chain_errors_summary AS
 SELECT chain,
    task,
    chain_name,
    task_name,
    message,
    command,
    count(*) AS entries,
    min(entered) AS entered_min,
    max(entered) AS entered_max
   FROM timetable.v_chain_errors
  GROUP BY chain, task, chain_name, task_name, message, command;


ALTER VIEW timetable.v_chain_errors_summary OWNER TO d3l243;

--
-- Name: TABLE v_chain_errors_summary; Type: ACL; Schema: timetable; Owner: d3l243
--

GRANT SELECT ON TABLE timetable.v_chain_errors_summary TO writeaccess;
GRANT INSERT,DELETE,TRUNCATE,UPDATE ON TABLE timetable.v_chain_errors_summary TO pgdms;

