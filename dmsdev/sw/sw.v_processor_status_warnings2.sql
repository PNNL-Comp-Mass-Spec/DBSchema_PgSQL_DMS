--
-- Name: v_processor_status_warnings2; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_processor_status_warnings2 AS
 SELECT processor_name,
    mgr_status,
    task_status,
    last_status_hours,
    status_date,
    most_recent_job_info,
    most_recent_log_message,
    most_recent_error_message,
    task_detail_status,
    job AS most_recent_job,
    dataset,
    step,
    script,
    tool,
    state_name,
    state,
    start,
    finish,
    runtime_minutes,
    last_cpu_status_minutes,
    job_progress,
    runtime_predicted_hours
   FROM ( SELECT ps.processor_name,
            ps.mgr_status,
            ps.task_status,
            ps.last_status_hours,
            ps.status_date,
            ps.most_recent_job_info,
            ps.most_recent_log_message,
            ps.most_recent_error_message,
            ps.task_detail_status,
            js.job,
            js.dataset,
            js.step,
            js.script,
            js.tool,
            js.state_name,
            js.state,
            js.start,
            js.finish,
            js.runtime_minutes,
            js.last_cpu_status_minutes,
            js.job_progress,
            js.runtime_predicted_hours,
            row_number() OVER (PARTITION BY ps.processor_name ORDER BY js.start DESC) AS startrank
           FROM (sw.v_processor_status_warnings ps
             LEFT JOIN sw.v_job_steps js ON ((ps.processor_name OPERATOR(public.=) js.processor)))) lookupq
  WHERE (startrank = 1);


ALTER VIEW sw.v_processor_status_warnings2 OWNER TO d3l243;

--
-- Name: TABLE v_processor_status_warnings2; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_processor_status_warnings2 TO readaccess;
GRANT SELECT ON TABLE sw.v_processor_status_warnings2 TO writeaccess;

