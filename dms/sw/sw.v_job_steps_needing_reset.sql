--
-- Name: v_job_steps_needing_reset; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_steps_needing_reset AS
 SELECT js.job,
    j.dataset,
    js.step,
    j.script,
    js.tool AS step_tool,
    js.state,
    js.start,
    js.finish,
    js_target.step AS dependent_step,
    js_target.tool AS dependent_step_tool,
    js_target.state AS dependent_step_state,
    js_target.start AS dependent_step_start,
    js_target.finish AS dependent_step_finish
   FROM (((sw.t_job_steps js
     JOIN sw.t_job_step_dependencies ON (((js.job = t_job_step_dependencies.job) AND (js.step = t_job_step_dependencies.step))))
     JOIN sw.t_job_steps js_target ON (((t_job_step_dependencies.job = js_target.job) AND (t_job_step_dependencies.target_step = js_target.step))))
     JOIN sw.t_jobs j ON ((js.job = j.job)))
  WHERE ((js.state >= 2) AND (js.state <> 3) AND ((js_target.state = ANY (ARRAY[2, 4])) OR (js_target.start > js.finish)));


ALTER VIEW sw.v_job_steps_needing_reset OWNER TO d3l243;

--
-- Name: TABLE v_job_steps_needing_reset; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_steps_needing_reset TO readaccess;
GRANT SELECT ON TABLE sw.v_job_steps_needing_reset TO writeaccess;

