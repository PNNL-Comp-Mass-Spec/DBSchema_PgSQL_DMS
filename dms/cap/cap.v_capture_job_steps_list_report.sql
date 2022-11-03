--
-- Name: v_capture_job_steps_list_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_job_steps_list_report AS
 SELECT js.job,
    js.step,
    s.script,
    js.step_tool AS tool,
    ssn.step_state,
    jsn.job_state AS job_state_b,
    js.retry_count AS retry,
    j.dataset,
    js.processor,
    js.start,
    js.finish,
    round((EXTRACT(epoch FROM (COALESCE((js.finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.start)::timestamp with time zone)) / 60.0), 2) AS runtime_minutes,
    js.state,
    js.input_folder_name AS input_folder,
    js.output_folder_name AS output_folder,
    j.priority,
    js.cpu_load,
    js.completion_code,
    js.completion_message,
    js.evaluation_code,
    js.evaluation_message,
    js.job_plus_step AS id,
    j.storage_server,
    j.instrument
   FROM ((((cap.t_task_steps js
     JOIN cap.t_task_step_state_name ssn ON ((js.state = ssn.step_state_id)))
     JOIN cap.t_tasks j ON ((js.job = j.job)))
     JOIN cap.t_task_state_name jsn ON ((j.state = jsn.job_state_id)))
     JOIN cap.t_scripts s ON ((j.script OPERATOR(public.=) s.script)));


ALTER TABLE cap.v_capture_job_steps_list_report OWNER TO d3l243;

--
-- Name: TABLE v_capture_job_steps_list_report; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_job_steps_list_report TO readaccess;
GRANT SELECT ON TABLE cap.v_capture_job_steps_list_report TO writeaccess;

