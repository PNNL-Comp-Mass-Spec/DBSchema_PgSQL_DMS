--
-- Name: v_tasks; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_tasks AS
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
    t.max_simultaneous_captures,
    t.results_folder_name,
    t.imported,
    t.start,
    t.finish,
    t.archive_busy,
    t.transfer_folder_path,
    t.comment,
    t.capture_subfolder
   FROM (cap.t_tasks t
     JOIN cap.t_task_state_name tsn ON ((t.state = tsn.job_state_id)));


ALTER TABLE cap.v_tasks OWNER TO d3l243;

--
-- Name: TABLE v_tasks; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_tasks TO readaccess;
GRANT SELECT ON TABLE cap.v_tasks TO writeaccess;

