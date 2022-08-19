--
-- Name: v_tasks; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_tasks AS
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
    j.max_simultaneous_captures,
    j.results_folder_name,
    j.imported,
    j.start,
    j.finish,
    j.archive_busy,
    j.transfer_folder_path,
    j.comment,
    j.capture_subfolder
   FROM (cap.t_tasks j
     JOIN cap.t_task_state_name jsn ON ((j.state = jsn.job_state_id)));


ALTER TABLE cap.v_tasks OWNER TO d3l243;

--
-- Name: TABLE v_tasks; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_tasks TO readaccess;

