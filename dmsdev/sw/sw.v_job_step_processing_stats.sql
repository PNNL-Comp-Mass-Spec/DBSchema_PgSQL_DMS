--
-- Name: v_job_step_processing_stats; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_step_processing_stats AS
 SELECT jsps.entered,
    jsps.job,
    j.dataset,
    jsps.step,
    j.script,
    js.tool,
    js.start,
    js.finish,
    jsps.runtime_minutes AS runtime_minutes_snapshot,
    js.runtime_minutes AS current_runtime_minutes,
    jsps.job_progress AS job_progress_snapshot,
    js.job_progress AS current_progress,
    jsps.runtime_predicted_hours AS runtime_predicted_hours_snapshot,
    js.runtime_predicted_hours AS current_runtime_predicted_hours,
    jsps.processor,
    lp.machine,
    jsps.prog_runner_core_usage,
    jsps.cpu_load,
    jsps.actual_cpu_load,
    jsn.step_state AS current_state_name,
    js.state AS current_state
   FROM ((((sw.t_job_step_processing_stats jsps
     LEFT JOIN sw.v_job_steps js ON (((js.job = jsps.job) AND (js.step = jsps.step))))
     JOIN sw.t_jobs j ON ((j.job = js.job)))
     JOIN sw.t_job_step_state_name jsn ON ((js.state = jsn.step_state_id)))
     LEFT JOIN sw.t_local_processors lp ON ((jsps.processor OPERATOR(public.=) lp.processor_name)));


ALTER VIEW sw.v_job_step_processing_stats OWNER TO d3l243;

--
-- Name: TABLE v_job_step_processing_stats; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_step_processing_stats TO readaccess;
GRANT SELECT ON TABLE sw.v_job_step_processing_stats TO writeaccess;

