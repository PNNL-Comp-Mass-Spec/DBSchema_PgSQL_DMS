--
-- Name: v_capture_job_steps_list_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_job_steps_list_report AS
 SELECT ts.job,
    ts.step,
    s.script,
    ts.step_tool AS tool,
    ssn.step_state,
    tsn.job_state AS job_state_b,
    ts.retry_count AS retry,
    t.dataset,
    ts.processor,
    ts.start,
    ts.finish,
    round((EXTRACT(epoch FROM (COALESCE((ts.finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (ts.start)::timestamp with time zone)) / 60.0), 2) AS runtime_minutes,
    ts.state,
    ts.input_folder_name AS input_folder,
    ts.output_folder_name AS output_folder,
    t.priority,
    ts.cpu_load,
    ts.completion_code,
    ts.completion_message,
    ts.evaluation_code,
    ts.evaluation_message,
    ts.job_plus_step AS id,
    t.storage_server,
    t.instrument
   FROM ((((cap.t_task_steps ts
     JOIN cap.t_task_step_state_name ssn ON ((ts.state = ssn.step_state_id)))
     JOIN cap.t_tasks t ON ((ts.job = t.job)))
     JOIN cap.t_task_state_name tsn ON ((t.state = tsn.job_state_id)))
     JOIN cap.t_scripts s ON ((t.script OPERATOR(public.=) s.script)));


ALTER TABLE cap.v_capture_job_steps_list_report OWNER TO d3l243;

--
-- Name: TABLE v_capture_job_steps_list_report; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_job_steps_list_report TO readaccess;
GRANT SELECT ON TABLE cap.v_capture_job_steps_list_report TO writeaccess;

