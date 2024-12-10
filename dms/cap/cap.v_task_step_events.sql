--
-- Name: v_task_step_events; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_task_step_events AS
 SELECT tse.event_id,
    tse.job,
    tse.step,
    tse.target_state,
    tse.prev_target_state,
    tsn.step_state AS target_state_name,
    psn.step_state AS previous_target_state_name,
    tse.entered,
    tse.entered_by
   FROM ((cap.t_task_step_events tse
     LEFT JOIN cap.t_task_step_state_name tsn ON ((tse.target_state = tsn.step_state_id)))
     LEFT JOIN cap.t_task_step_state_name psn ON ((tse.prev_target_state = psn.step_state_id)));


ALTER VIEW cap.v_task_step_events OWNER TO d3l243;

--
-- Name: TABLE v_task_step_events; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_task_step_events TO readaccess;
GRANT SELECT ON TABLE cap.v_task_step_events TO writeaccess;

