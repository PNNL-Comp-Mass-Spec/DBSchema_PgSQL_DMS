--
-- Name: v_task_steps_history; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_task_steps_history AS
 SELECT js.job,
    j.dataset,
    j.dataset_id,
    js.step,
    s.script,
    js.step_tool AS tool,
    ssn.step_state AS state_name,
    js.state,
    js.start,
    js.finish,
    round((EXTRACT(epoch FROM (COALESCE((js.finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.start)::timestamp with time zone)) / 60.0), 1) AS runtime_minutes,
    js.processor,
    js.input_folder_name AS input_folder,
    js.output_folder_name AS output_folder,
    j.priority,
    js.completion_code,
    js.completion_message,
    js.evaluation_code,
    js.evaluation_message,
    instname.instrument,
    js.tool_version_id,
    stv.tool_version,
    dfp.dataset_folder_path,
    j.state AS job_state
   FROM (((((((cap.t_task_steps_history js
     JOIN cap.t_task_step_state_name ssn ON ((js.state = ssn.step_state_id)))
     JOIN cap.t_tasks_history j ON (((js.job = j.job) AND (js.saved = j.saved))))
     JOIN cap.t_scripts s ON ((j.script OPERATOR(public.=) s.script)))
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     LEFT JOIN public.t_cached_dataset_folder_paths dfp ON ((j.dataset_id = dfp.dataset_id)))
     LEFT JOIN cap.t_step_tool_versions stv ON ((js.tool_version_id = stv.tool_version_id)));


ALTER TABLE cap.v_task_steps_history OWNER TO d3l243;

--
-- Name: TABLE v_task_steps_history; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_task_steps_history TO readaccess;

