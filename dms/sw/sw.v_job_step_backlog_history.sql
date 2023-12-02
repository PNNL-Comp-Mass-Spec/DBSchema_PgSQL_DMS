--
-- Name: v_job_step_backlog_history; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_step_backlog_history AS
 SELECT t_job_step_status_history.step_tool,
    t_job_step_status_history.posting_time,
    sum(t_job_step_status_history.step_count) AS backlog_count
   FROM sw.t_job_step_status_history
  WHERE (t_job_step_status_history.state = ANY (ARRAY[2, 4]))
  GROUP BY t_job_step_status_history.step_tool, t_job_step_status_history.posting_time;


ALTER VIEW sw.v_job_step_backlog_history OWNER TO d3l243;

--
-- Name: TABLE v_job_step_backlog_history; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_step_backlog_history TO readaccess;
GRANT SELECT ON TABLE sw.v_job_step_backlog_history TO writeaccess;

