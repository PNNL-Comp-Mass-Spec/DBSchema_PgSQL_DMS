--
-- Name: v_capture_jobs_detail_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_jobs_detail_report AS
 SELECT j.job,
    j.priority,
    j.script,
    jsn.job_state AS job_state_b,
    'Steps'::text AS steps,
    j.dataset,
    j.dataset_id,
    j.results_folder_name,
    j.imported,
    j.finish,
    j.storage_server,
    j.instrument,
    j.instrument_class,
    j.max_simultaneous_captures,
    j.comment,
    j.capture_subfolder,
    cap.get_task_param_list(j.job) AS parameters
   FROM (cap.t_tasks j
     JOIN cap.t_task_state_name jsn ON ((j.state = jsn.job_state_id)));


ALTER TABLE cap.v_capture_jobs_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_capture_jobs_detail_report; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_jobs_detail_report TO readaccess;

