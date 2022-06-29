--
-- Name: v_capture_check_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_check_report AS
 SELECT j.job,
    j.script,
    taskstatename.job_state AS state,
    statsq.steps_retrying AS retry,
    statsq.num_steps AS steps,
    (((jobsteps.step_tool)::text || ':'::text) || (stepstatename.step_state)::text) AS active_step,
    j.dataset,
    j.results_folder_name,
    j.storage_server,
    j.priority,
    j.imported,
    j.start,
    j.finish,
    j.instrument,
    j.instrument_class,
    j.max_simultaneous_captures,
    j.comment
   FROM ((((cap.t_tasks j
     JOIN cap.t_task_state_name taskstatename ON ((j.state = taskstatename.job_state_id)))
     JOIN ( SELECT filteredsteps.job,
            count(filteredsteps.step) AS num_steps,
            max(
                CASE
                    WHEN (filteredsteps.state <> 1) THEN filteredsteps.step
                    ELSE 0
                END) AS active_step,
            sum(
                CASE
                    WHEN ((filteredsteps.retry_count > 0) AND (filteredsteps.retry_count < tst.number_of_retries)) THEN 1
                    ELSE 0
                END) AS steps_retrying
           FROM ((cap.t_task_steps filteredsteps
             JOIN cap.t_step_tools tst ON ((filteredsteps.step_tool OPERATOR(public.=) tst.step_tool)))
             JOIN cap.t_tasks j_1 ON ((filteredsteps.job = j_1.job)))
          WHERE (NOT (j_1.state = ANY (ARRAY[3, 101])))
          GROUP BY filteredsteps.job) statsq ON ((statsq.job = j.job)))
     JOIN cap.t_task_steps jobsteps ON (((j.job = jobsteps.job) AND (statsq.active_step = jobsteps.step))))
     JOIN cap.t_task_step_state_name stepstatename ON ((jobsteps.state = stepstatename.step_state_id)));


ALTER TABLE cap.v_capture_check_report OWNER TO d3l243;

