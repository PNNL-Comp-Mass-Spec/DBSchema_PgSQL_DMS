--
-- Name: v_tasks_history_detail_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_tasks_history_detail_report AS
 SELECT j.job,
    j.priority,
    j.script,
    jsn.job_state,
    j.state AS job_state_id,
    COALESCE(js.steps, (0)::bigint) AS steps,
    j.dataset,
    j.results_folder_name,
    j.imported,
    j.start,
    j.finish,
    (jp.parameters)::text AS parameters
   FROM (((cap.t_tasks_history j
     JOIN cap.t_task_state_name jsn ON ((j.state = jsn.job_state_id)))
     LEFT JOIN cap.t_task_parameters_history jp ON (((j.job = jp.job) AND (jp.most_recent_entry = 1))))
     LEFT JOIN ( SELECT t_task_steps_history.job,
            count(*) AS steps
           FROM cap.t_task_steps_history
          WHERE (t_task_steps_history.most_recent_entry = 1)
          GROUP BY t_task_steps_history.job) js ON ((j.job = js.job)))
  WHERE (j.most_recent_entry = 1);


ALTER TABLE cap.v_tasks_history_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_tasks_history_detail_report; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_tasks_history_detail_report TO readaccess;

