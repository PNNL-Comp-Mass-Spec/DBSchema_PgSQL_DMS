--
-- Name: v_job_step_events; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_step_events AS
 SELECT jse.event_id,
    jse.job,
    jse.step,
    jse.target_state,
    jse.prev_target_state,
    tsn.step_state AS target_state_name,
    psn.step_state AS previous_target_state_name,
    jse.entered,
    jse.entered_by
   FROM ((sw.t_job_step_events jse
     LEFT JOIN sw.t_job_step_state_name tsn ON ((jse.target_state = tsn.step_state_id)))
     LEFT JOIN sw.t_job_step_state_name psn ON ((jse.prev_target_state = psn.step_state_id)));


ALTER VIEW sw.v_job_step_events OWNER TO d3l243;

--
-- Name: TABLE v_job_step_events; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_step_events TO readaccess;
GRANT SELECT ON TABLE sw.v_job_step_events TO writeaccess;

