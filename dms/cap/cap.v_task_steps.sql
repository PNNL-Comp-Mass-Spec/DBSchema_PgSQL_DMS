--
-- Name: v_task_steps; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_task_steps AS
 SELECT ts.job,
    ts.dataset,
    ts.dataset_id,
    ts.step,
    ts.script,
    ts.tool,
    ts.state_name,
    ts.state,
    ts.start,
    ts.finish,
    ts.runtime_minutes,
    ((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (ps.status_date)::timestamp with time zone)) / (60)::numeric))::integer AS last_cpu_status_minutes,
        CASE
            WHEN (ts.state = 4) THEN ps.progress
            WHEN (ts.state = 5) THEN (100)::real
            ELSE (0)::real
        END AS job_progress,
        CASE
            WHEN ((ts.state = 4) AND (ps.progress > (0)::double precision)) THEN round(((((ts.runtime_minutes)::double precision / (ps.progress / (100.0)::double precision)) / (60.0)::double precision))::numeric, 2)
            ELSE (0)::numeric
        END AS runtime_predicted_hours,
    ts.processor,
        CASE
            WHEN (ts.state = 4) THEN ps.process_id
            ELSE NULL::integer
        END AS process_id,
    ts.input_folder,
    ts.output_folder,
    ts.priority,
    ts.dependencies,
    ts.cpu_load,
    ts.tool_version_id,
    ts.tool_version,
    ts.completion_code,
    ts.completion_message,
    ts.evaluation_code,
    ts.evaluation_message,
    ts.holdoff_interval_minutes,
    ts.next_try,
    ts.retry_count,
    ts.instrument,
    ('http://dms2.pnl.gov/helper_inst_source/view/'::text || (ts.instrument)::text) AS instrument_source_files,
    ts.storage_server,
    ts.transfer_folder_path,
    ts.dataset_folder_path,
    ts.capture_subfolder,
    ts.job_state,
    ((((('\\'::text || (lp.machine)::text) ||
        CASE
            WHEN m.bionet_only THEN '.bionet'::text
            ELSE ''::text
        END) || '\DMS_Programs\CaptureTaskManager'::text) ||
        CASE
            WHEN (ts.processor OPERATOR(public.~) similar_to_escape('%_[2-9]'::text)) THEN ('_'::text || "right"((ts.processor)::text, 1))
            ELSE ''::text
        END) || '\Logs\'::text) AS log_file_path
   FROM (((( SELECT ts_1.job,
            t.dataset,
            t.dataset_id,
            ts_1.step,
            t.script,
            ts_1.tool,
            ssn.step_state AS state_name,
            ts_1.state,
            ts_1.start,
            ts_1.finish,
            round((EXTRACT(epoch FROM (COALESCE((ts_1.finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (ts_1.start)::timestamp with time zone)) / (60)::numeric), 1) AS runtime_minutes,
            ts_1.processor,
            ts_1.input_folder_name AS input_folder,
            ts_1.output_folder_name AS output_folder,
            t.priority,
            ts_1.dependencies,
            ts_1.cpu_load,
            ts_1.completion_code,
            ts_1.completion_message,
            ts_1.evaluation_code,
            ts_1.evaluation_message,
            ts_1.holdoff_interval_minutes,
            ts_1.next_try,
            ts_1.retry_count,
            t.instrument,
            t.storage_server,
            t.transfer_folder_path,
            ts_1.tool_version_id,
            stv.tool_version,
            dfp.dataset_folder_path,
            t.capture_subfolder,
            t.state AS job_state
           FROM ((((cap.t_task_steps ts_1
             JOIN cap.t_task_step_state_name ssn ON ((ts_1.state = ssn.step_state_id)))
             JOIN cap.t_tasks t ON ((ts_1.job = t.job)))
             LEFT JOIN public.t_cached_dataset_folder_paths dfp ON ((t.dataset_id = dfp.dataset_id)))
             LEFT JOIN cap.t_step_tool_versions stv ON ((ts_1.tool_version_id = stv.tool_version_id)))
          WHERE (t.state <> 101)) ts
     LEFT JOIN cap.t_processor_status ps ON ((ts.processor OPERATOR(public.=) ps.processor_name)))
     LEFT JOIN cap.t_local_processors lp ON ((ts.processor OPERATOR(public.=) lp.processor_name)))
     LEFT JOIN cap.t_machines m ON ((lp.machine OPERATOR(public.=) m.machine)));


ALTER VIEW cap.v_task_steps OWNER TO d3l243;

--
-- Name: v_task_steps trig_v_task_steps_instead_of_update; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_v_task_steps_instead_of_update INSTEAD OF UPDATE ON cap.v_task_steps FOR EACH ROW EXECUTE FUNCTION cap.trigfn_v_task_steps_instead_of_update();

--
-- Name: TABLE v_task_steps; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_task_steps TO readaccess;
GRANT SELECT ON TABLE cap.v_task_steps TO writeaccess;

