--
-- Name: v_capture_jobs_active_or_complete; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_jobs_active_or_complete AS
 SELECT j.job,
    j.priority,
    j.script,
    j.state,
    jsn.job_state AS state_name,
    j.dataset,
    j.dataset_id,
    j.storage_server,
    j.instrument,
    j.instrument_class,
    j.imported,
    j.start,
    j.finish,
    sum(
        CASE
            WHEN (js.state = ANY (ARRAY[2, 4, 5])) THEN 1
            ELSE 0
        END) AS step_count_active_or_complete
   FROM ((cap.t_tasks j
     JOIN cap.t_task_state_name jsn ON ((j.state = jsn.job_state_id)))
     LEFT JOIN cap.t_task_steps js ON ((j.job = js.job)))
  WHERE ((j.script OPERATOR(public.~~) '%DatasetCapture%'::public.citext) AND ((j.state = ANY (ARRAY[0, 1, 2, 3, 6, 9, 20, 100])) OR (js.state = ANY (ARRAY[2, 4, 5]))))
  GROUP BY j.job, j.priority, j.script, j.state, jsn.job_state, j.dataset, j.dataset_id, j.storage_server, j.instrument, j.instrument_class, j.results_folder_name, j.imported, j.start, j.finish;


ALTER TABLE cap.v_capture_jobs_active_or_complete OWNER TO d3l243;

--
-- Name: TABLE v_capture_jobs_active_or_complete; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_jobs_active_or_complete TO readaccess;
GRANT SELECT ON TABLE cap.v_capture_jobs_active_or_complete TO writeaccess;

