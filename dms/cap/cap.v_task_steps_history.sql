--
-- Name: v_task_steps_history; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_task_steps_history AS
 SELECT ts.job,
    t.dataset,
    t.dataset_id,
    ts.step,
    s.script,
    ts.step_tool AS tool,
    ssn.step_state AS state_name,
    ts.state,
    ts.start,
    ts.finish,
    round((EXTRACT(epoch FROM (COALESCE((ts.finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (ts.start)::timestamp with time zone)) / 60.0), 1) AS runtime_minutes,
    ts.processor,
    ts.input_folder_name AS input_folder,
    ts.output_folder_name AS output_folder,
    t.priority,
    ts.completion_code,
    ts.completion_message,
    ts.evaluation_code,
    ts.evaluation_message,
    instname.instrument,
    ts.tool_version_id,
    stv.tool_version,
    dfp.dataset_folder_path,
    t.state AS job_state,
    ts.saved
   FROM (((((((cap.t_task_steps_history ts
     JOIN cap.t_task_step_state_name ssn ON ((ts.state = ssn.step_state_id)))
     JOIN cap.t_tasks_history t ON (((ts.job = t.job) AND (ts.saved = t.saved))))
     JOIN cap.t_scripts s ON ((t.script OPERATOR(public.=) s.script)))
     JOIN public.t_dataset ds ON ((t.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     LEFT JOIN public.t_cached_dataset_folder_paths dfp ON ((t.dataset_id = dfp.dataset_id)))
     LEFT JOIN cap.t_step_tool_versions stv ON ((ts.tool_version_id = stv.tool_version_id)));


ALTER TABLE cap.v_task_steps_history OWNER TO d3l243;

--
-- Name: TABLE v_task_steps_history; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_task_steps_history TO readaccess;
GRANT SELECT ON TABLE cap.v_task_steps_history TO writeaccess;

