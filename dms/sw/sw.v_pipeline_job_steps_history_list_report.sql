--
-- Name: v_pipeline_job_steps_history_list_report; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_job_steps_history_list_report AS
 SELECT js.job,
    js.step,
    j.script,
    js.step_tool AS tool,
    ssn.step_state,
    jsn.job_state AS job_state_b,
    j.dataset,
    js.start,
    js.finish,
    round((EXTRACT(epoch FROM (COALESCE((js.finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.start)::timestamp with time zone)) / 60.0), 2) AS runtime,
    js.processor,
    js.state,
        CASE
            WHEN (js.state = 5) THEN 100
            ELSE 0
        END AS job_progress,
        CASE
            WHEN (js.state = 5) THEN round(((EXTRACT(epoch FROM (COALESCE((js.finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.start)::timestamp with time zone)) / 60.0) / 60.0), 2)
            ELSE (0)::numeric
        END AS runtime_predicted_hours,
    0 AS last_cpu_status_minutes,
    js.input_folder_name AS input_folder,
    js.output_folder_name AS output_folder,
    j.priority,
    js.signature,
    0 AS cpu_load,
    0 AS actual_cpu_load,
    js.memory_usage_mb,
    js.tool_version_id,
    js.completion_code,
    js.completion_message,
    js.evaluation_code,
    js.evaluation_message,
    js.job_step_saved_combo AS id
   FROM (((sw.t_job_steps_history js
     JOIN sw.t_job_step_state_name ssn ON ((js.state = ssn.step_state_id)))
     JOIN ( SELECT t_jobs_history.job,
            t_jobs_history.dataset,
            t_jobs_history.script,
            t_jobs_history.state,
            t_jobs_history.priority
           FROM sw.t_jobs_history
          WHERE (t_jobs_history.most_recent_entry = 1)) j ON ((js.job = j.job)))
     JOIN sw.t_job_state_name jsn ON ((j.state = jsn.job_state_id)))
  WHERE (js.most_recent_entry = 1);


ALTER TABLE sw.v_pipeline_job_steps_history_list_report OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_job_steps_history_list_report; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_job_steps_history_list_report TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_job_steps_history_list_report TO writeaccess;

