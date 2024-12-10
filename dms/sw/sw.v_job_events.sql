--
-- Name: v_job_events; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_events AS
 SELECT je.event_id,
    je.job,
    je.target_state,
    je.prev_target_state,
    tsn.job_state AS target_state_name,
    psn.job_state AS prev_target_state_name,
    je.entered,
    je.entered_by
   FROM ((sw.t_job_events je
     LEFT JOIN sw.t_job_state_name tsn ON ((je.target_state = tsn.job_state_id)))
     LEFT JOIN sw.t_job_state_name psn ON ((je.prev_target_state = psn.job_state_id)));


ALTER VIEW sw.v_job_events OWNER TO d3l243;

--
-- Name: TABLE v_job_events; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_events TO readaccess;
GRANT SELECT ON TABLE sw.v_job_events TO writeaccess;

