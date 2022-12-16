--
-- Name: v_job_step_state_summary_recent; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_step_state_summary_recent AS
 SELECT js.step_tool,
    js.state,
    ssn.step_state AS state_name,
    count(*) AS step_count,
    max(js.start) AS start_max
   FROM (sw.t_job_steps js
     JOIN sw.t_job_step_state_name ssn ON ((js.state = ssn.step_state_id)))
  WHERE (js.job IN ( SELECT DISTINCT t_job_step_events.job
           FROM sw.t_job_step_events
          WHERE (t_job_step_events.entered >= (CURRENT_TIMESTAMP - '120 days'::interval))))
  GROUP BY js.step_tool, js.state, ssn.step_state;


ALTER TABLE sw.v_job_step_state_summary_recent OWNER TO d3l243;

--
-- Name: TABLE v_job_step_state_summary_recent; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_step_state_summary_recent TO readaccess;
GRANT SELECT ON TABLE sw.v_job_step_state_summary_recent TO writeaccess;

