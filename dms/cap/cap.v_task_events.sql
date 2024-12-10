--
-- Name: v_task_events; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_task_events AS
 SELECT te.event_id,
    te.job,
    te.target_state,
    te.prev_target_state,
    tsn.job_state AS target_state_name,
    psn.job_state AS prev_target_state_name,
    te.entered,
    te.entered_by
   FROM ((cap.t_task_events te
     LEFT JOIN cap.t_task_state_name tsn ON ((te.target_state = tsn.job_state_id)))
     LEFT JOIN cap.t_task_state_name psn ON ((te.prev_target_state = psn.job_state_id)));


ALTER VIEW cap.v_task_events OWNER TO d3l243;

--
-- Name: TABLE v_task_events; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_task_events TO readaccess;
GRANT SELECT ON TABLE cap.v_task_events TO writeaccess;

