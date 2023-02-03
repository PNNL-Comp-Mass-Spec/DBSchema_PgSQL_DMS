--
-- Name: v_helper_dataset_capture_job_steps_ckbx; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_helper_dataset_capture_job_steps_ckbx AS
 SELECT t.dataset,
    t.job,
    s.script,
    tsn.job_state,
    t.storage_server,
    t.instrument,
    t.start,
    t.finish
   FROM ((cap.t_tasks t
     JOIN cap.t_task_state_name tsn ON ((t.state = tsn.job_state_id)))
     JOIN cap.t_scripts s ON ((t.script OPERATOR(public.=) s.script)));


ALTER TABLE cap.v_helper_dataset_capture_job_steps_ckbx OWNER TO d3l243;

--
-- Name: TABLE v_helper_dataset_capture_job_steps_ckbx; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_helper_dataset_capture_job_steps_ckbx TO readaccess;
GRANT SELECT ON TABLE cap.v_helper_dataset_capture_job_steps_ckbx TO writeaccess;

