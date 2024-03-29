--
-- Name: v_task_step_backlog_history; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_task_step_backlog_history AS
 SELECT t_task_step_status_history.step_tool,
    t_task_step_status_history.posting_time,
    sum(t_task_step_status_history.step_count) AS backlog_count
   FROM cap.t_task_step_status_history
  WHERE (t_task_step_status_history.state = ANY (ARRAY[2, 4]))
  GROUP BY t_task_step_status_history.step_tool, t_task_step_status_history.posting_time;


ALTER VIEW cap.v_task_step_backlog_history OWNER TO d3l243;

--
-- Name: TABLE v_task_step_backlog_history; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_task_step_backlog_history TO readaccess;
GRANT SELECT ON TABLE cap.v_task_step_backlog_history TO writeaccess;

