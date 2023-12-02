--
-- Name: v_step_dependencies; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_step_dependencies AS
 SELECT jsd.job,
    jsd.step,
    js.tool AS step_tool,
    jsd.target_step,
    jsd.condition_test,
    jsd.test_value,
    jsd.evaluated,
    jsd.triggered,
    jsd.enable_only,
    js.state
   FROM (sw.t_job_step_dependencies jsd
     JOIN sw.t_job_steps js ON (((jsd.job = js.job) AND (jsd.step = js.step))));


ALTER VIEW sw.v_step_dependencies OWNER TO d3l243;

--
-- Name: TABLE v_step_dependencies; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_step_dependencies TO readaccess;
GRANT SELECT ON TABLE sw.v_step_dependencies TO writeaccess;

