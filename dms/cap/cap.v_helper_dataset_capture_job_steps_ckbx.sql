--
-- Name: v_helper_dataset_capture_job_steps_ckbx; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_helper_dataset_capture_job_steps_ckbx AS
 SELECT j.dataset,
    j.job,
    s.script,
    jsn.job_state,
    j.storage_server,
    j.instrument,
    j.start,
    j.finish
   FROM ((cap.t_tasks j
     JOIN cap.t_task_state_name jsn ON ((j.state = jsn.job_state_id)))
     JOIN cap.t_scripts s ON ((j.script OPERATOR(public.=) s.script)));


ALTER TABLE cap.v_helper_dataset_capture_job_steps_ckbx OWNER TO d3l243;

--
-- Name: TABLE v_helper_dataset_capture_job_steps_ckbx; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_helper_dataset_capture_job_steps_ckbx TO readaccess;

