--
-- Name: v_tasks_history_detail_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_tasks_history_detail_report AS
 SELECT t.job,
    t.priority,
    t.script,
    tsn.job_state,
    t.state AS job_state_id,
    COALESCE(ts.steps, (0)::bigint) AS steps,
    t.dataset,
    t.results_folder_name,
    t.imported,
    t.start,
    t.finish,
    (jp.parameters)::text AS parameters
   FROM (((cap.t_tasks_history t
     JOIN cap.t_task_state_name tsn ON ((t.state = tsn.job_state_id)))
     LEFT JOIN cap.t_task_parameters_history jp ON (((t.job = jp.job) AND (jp.most_recent_entry = 1))))
     LEFT JOIN ( SELECT t_task_steps_history.job,
            count(t_task_steps_history.step) AS steps
           FROM cap.t_task_steps_history
          WHERE (t_task_steps_history.most_recent_entry = 1)
          GROUP BY t_task_steps_history.job) ts ON ((t.job = ts.job)))
  WHERE (t.most_recent_entry = 1);


ALTER VIEW cap.v_tasks_history_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_tasks_history_detail_report; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_tasks_history_detail_report TO readaccess;
GRANT SELECT ON TABLE cap.v_tasks_history_detail_report TO writeaccess;

