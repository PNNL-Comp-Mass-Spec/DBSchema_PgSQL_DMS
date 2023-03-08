--
-- Name: v_capture_jobs_list_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_jobs_list_report AS
 SELECT t.job,
    t.priority,
    t.script,
    taskstatename.job_state AS job_state_b,
    statsq.num_steps AS steps,
    (((ts.tool)::text || ':'::text) || (ssn.step_state)::text) AS active_step,
    t.dataset,
    t.dataset_id,
    t.results_folder_name,
    t.imported,
    t.start,
    t.finish,
    t.storage_server,
    t.instrument,
    t.instrument_class,
    t.max_simultaneous_captures,
    t.comment
   FROM ((((cap.t_tasks t
     JOIN cap.t_task_state_name taskstatename ON ((t.state = taskstatename.job_state_id)))
     JOIN ( SELECT tasksteps.job,
            count(tasksteps.step) AS num_steps,
            max(
                CASE
                    WHEN (tasksteps.state <> 1) THEN tasksteps.step
                    ELSE 0
                END) AS active_step,
            sum(
                CASE
                    WHEN ((tasksteps.retry_count > 0) AND (tasksteps.retry_count < steptools.number_of_retries)) THEN 1
                    ELSE 0
                END) AS steps_retrying
           FROM ((cap.t_task_steps tasksteps
             JOIN cap.t_step_tools steptools ON ((tasksteps.tool OPERATOR(public.=) steptools.step_tool)))
             JOIN cap.t_tasks j_1 ON ((tasksteps.job = j_1.job)))
          GROUP BY tasksteps.job) statsq ON ((statsq.job = t.job)))
     JOIN cap.t_task_steps ts ON (((t.job = ts.job) AND (statsq.active_step = ts.step))))
     JOIN cap.t_task_step_state_name ssn ON ((ts.state = ssn.step_state_id)));


ALTER TABLE cap.v_capture_jobs_list_report OWNER TO d3l243;

--
-- Name: TABLE v_capture_jobs_list_report; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_jobs_list_report TO readaccess;
GRANT SELECT ON TABLE cap.v_capture_jobs_list_report TO writeaccess;

