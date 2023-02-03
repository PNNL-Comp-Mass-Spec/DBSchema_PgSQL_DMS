--
-- Name: v_capture_jobs_detail_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_jobs_detail_report AS
 SELECT t.job,
    t.priority,
    t.script,
    tsn.job_state AS job_state_b,
    'Steps'::text AS steps,
    t.dataset,
    t.dataset_id,
    t.results_folder_name,
    t.imported,
    t.finish,
    t.storage_server,
    t.instrument,
    t.instrument_class,
    t.max_simultaneous_captures,
    t.comment,
    t.capture_subfolder,
    cap.get_task_param_list(t.job) AS parameters
   FROM (cap.t_tasks t
     JOIN cap.t_task_state_name tsn ON ((t.state = tsn.job_state_id)));


ALTER TABLE cap.v_capture_jobs_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_capture_jobs_detail_report; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_jobs_detail_report TO readaccess;
GRANT SELECT ON TABLE cap.v_capture_jobs_detail_report TO writeaccess;

