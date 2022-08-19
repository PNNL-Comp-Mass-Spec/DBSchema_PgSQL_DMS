--
-- Name: v_capture_jobs_entry; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_jobs_entry AS
 SELECT t_tasks.job,
    t_tasks.priority,
    t_tasks.script AS script_name,
    t_tasks.results_folder_name,
    t_tasks.comment,
    (t_task_parameters.parameters)::text AS job_param
   FROM (cap.t_tasks
     JOIN cap.t_task_parameters ON ((t_tasks.job = t_task_parameters.job)));


ALTER TABLE cap.v_capture_jobs_entry OWNER TO d3l243;

--
-- Name: TABLE v_capture_jobs_entry; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_jobs_entry TO readaccess;

