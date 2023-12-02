--
-- Name: v_capture_tasks_active_or_complete; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_tasks_active_or_complete AS
 SELECT t.job,
    t.priority,
    t.script,
    t.state,
    tsn.job_state AS state_name,
    t.dataset,
    t.dataset_id,
    t.storage_server,
    t.instrument,
    t.instrument_class,
    t.imported,
    t.start,
    t.finish,
    sum(
        CASE
            WHEN (ts.state = ANY (ARRAY[2, 4, 5])) THEN 1
            ELSE 0
        END) AS step_count_active_or_complete
   FROM ((cap.t_tasks t
     JOIN cap.t_task_state_name tsn ON ((t.state = tsn.job_state_id)))
     LEFT JOIN cap.t_task_steps ts ON ((t.job = ts.job)))
  WHERE ((t.script OPERATOR(public.~~) '%DatasetCapture%'::public.citext) AND ((t.state = ANY (ARRAY[0, 1, 2, 3, 6, 9, 20, 100])) OR (ts.state = ANY (ARRAY[2, 4, 5]))))
  GROUP BY t.job, t.priority, t.script, t.state, tsn.job_state, t.dataset, t.dataset_id, t.storage_server, t.instrument, t.instrument_class, t.results_folder_name, t.imported, t.start, t.finish;


ALTER VIEW cap.v_capture_tasks_active_or_complete OWNER TO d3l243;

--
-- Name: TABLE v_capture_tasks_active_or_complete; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_tasks_active_or_complete TO readaccess;
GRANT SELECT ON TABLE cap.v_capture_tasks_active_or_complete TO writeaccess;

