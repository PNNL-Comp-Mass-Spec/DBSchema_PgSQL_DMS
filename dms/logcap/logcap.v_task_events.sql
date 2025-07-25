--
-- Name: v_task_events; Type: VIEW; Schema: logcap; Owner: d3l243
--

CREATE VIEW logcap.v_task_events AS
 SELECT te.event_id,
    te.job,
    te.target_state,
    te.prev_target_state,
    tsn.job_state AS target_state_name,
    psn.job_state AS previous_target_state_name,
    te.entered,
    te.entered_by
   FROM ((logcap.t_task_events te
     LEFT JOIN cap.t_task_state_name tsn ON ((te.target_state = tsn.job_state_id)))
     LEFT JOIN cap.t_task_state_name psn ON ((te.prev_target_state = psn.job_state_id)));


ALTER VIEW logcap.v_task_events OWNER TO d3l243;

--
-- Name: TABLE v_task_events; Type: ACL; Schema: logcap; Owner: d3l243
--

GRANT SELECT ON TABLE logcap.v_task_events TO writeaccess;

