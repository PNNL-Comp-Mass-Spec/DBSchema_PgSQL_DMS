--
-- Name: v_task_steps; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_task_steps AS
 SELECT js.job,
    js.dataset,
    js.dataset_id,
    js.step,
    js.script,
    js.tool,
    js.state_name,
    js.state,
    js.start,
    js.finish,
    js.runtime_minutes,
    ((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (ps.status_date)::timestamp with time zone)) / 60.0))::integer AS last_cpu_status_minutes,
        CASE
            WHEN (js.state = 4) THEN ps.progress
            WHEN (js.state = 5) THEN (100)::real
            ELSE (0)::real
        END AS job_progress,
        CASE
            WHEN ((js.state = 4) AND (ps.progress > (0)::double precision)) THEN round(((((js.runtime_minutes)::double precision / (ps.progress / (100.0)::double precision)) / (60.0)::double precision))::numeric, 2)
            ELSE (0)::numeric
        END AS runtime_predicted_hours,
    js.processor,
        CASE
            WHEN (js.state = 4) THEN ps.process_id
            ELSE NULL::integer
        END AS process_id,
    js.input_folder,
    js.output_folder,
    js.priority,
    js.dependencies,
    js.cpu_load,
    js.tool_version_id,
    js.tool_version,
    js.completion_code,
    js.completion_message,
    js.evaluation_code,
    js.evaluation_message,
    js.holdoff_interval_minutes,
    js.next_try,
    js.retry_count,
    js.instrument,
    ('http://dms2.pnl.gov/helper_inst_source/view/'::text || (js.instrument)::text) AS instrument_source_files,
    js.storage_server,
    js.transfer_folder_path,
    js.dataset_folder_path,
    js.capture_subfolder,
    js.job_state
   FROM (( SELECT js_1.job,
            j.dataset,
            j.dataset_id,
            js_1.step,
            s.script,
            js_1.step_tool AS tool,
            ssn.step_state AS state_name,
            js_1.state,
            js_1.start,
            js_1.finish,
            round((EXTRACT(epoch FROM (COALESCE((js_1.finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js_1.start)::timestamp with time zone)) / 60.0), 1) AS runtime_minutes,
            js_1.processor,
            js_1.input_folder_name AS input_folder,
            js_1.output_folder_name AS output_folder,
            j.priority,
            js_1.dependencies,
            js_1.cpu_load,
            js_1.completion_code,
            js_1.completion_message,
            js_1.evaluation_code,
            js_1.evaluation_message,
            js_1.holdoff_interval_minutes,
            js_1.next_try,
            js_1.retry_count,
            j.instrument,
            j.storage_server,
            j.transfer_folder_path,
            js_1.tool_version_id,
            stv.tool_version,
            dfp.dataset_folder_path,
            j.capture_subfolder,
            j.state AS job_state
           FROM (((((cap.t_task_steps js_1
             JOIN cap.t_task_step_state_name ssn ON ((js_1.state = ssn.step_state_id)))
             JOIN cap.t_tasks j ON ((js_1.job = j.job)))
             JOIN cap.t_scripts s ON ((j.script OPERATOR(public.=) s.script)))
             LEFT JOIN public.t_cached_dataset_folder_paths dfp ON ((j.dataset_id = dfp.dataset_id)))
             LEFT JOIN cap.t_step_tool_versions stv ON ((js_1.tool_version_id = stv.tool_version_id)))
          WHERE (j.state <> 101)) js
     LEFT JOIN cap.t_processor_status ps ON ((js.processor OPERATOR(public.=) ps.processor_name)));


ALTER TABLE cap.v_task_steps OWNER TO d3l243;

--
-- Name: TABLE v_task_steps; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_task_steps TO readaccess;

