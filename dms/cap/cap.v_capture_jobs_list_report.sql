--
-- Name: v_capture_jobs_list_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_jobs_list_report AS
 SELECT j.job,
    j.priority,
    j.script,
    taskstatename.job_state AS job_state_b,
    statsq.num_steps AS steps,
    (((js.step_tool)::text || ':'::text) || (ssn.step_state)::text) AS active_step,
    j.dataset,
    j.dataset_id AS ds_id,
    j.results_folder_name,
    j.imported,
    j.start,
    j.finish,
    j.storage_server,
    j.instrument,
    j.instrument_class,
    j.max_simultaneous_captures,
    j.comment
   FROM ((((cap.t_tasks j
     JOIN cap.t_task_state_name taskstatename ON ((j.state = taskstatename.job_state_id)))
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
             JOIN cap.t_step_tools steptools ON ((tasksteps.step_tool OPERATOR(public.=) steptools.step_tool)))
             JOIN cap.t_tasks j_1 ON ((tasksteps.job = j_1.job)))
          GROUP BY tasksteps.job) statsq ON ((statsq.job = j.job)))
     JOIN cap.t_task_steps js ON (((j.job = js.job) AND (statsq.active_step = js.step))))
     JOIN cap.t_task_step_state_name ssn ON ((js.state = ssn.step_state_id)));


ALTER TABLE cap.v_capture_jobs_list_report OWNER TO d3l243;

--
-- Name: TABLE v_capture_jobs_list_report; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_jobs_list_report TO readaccess;

