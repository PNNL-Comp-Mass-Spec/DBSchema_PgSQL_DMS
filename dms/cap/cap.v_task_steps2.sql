--
-- Name: v_task_steps2; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_task_steps2 AS
 SELECT lookupq.job,
    lookupq.dataset,
    lookupq.dataset_id,
    lookupq.step,
    lookupq.script,
    lookupq.tool,
    lookupq.state_name,
    lookupq.state,
    lookupq.start,
    lookupq.finish,
    lookupq.runtime_minutes,
    lookupq.last_cpu_status_minutes,
    lookupq.job_progress,
    lookupq.runtime_predicted_hours,
    lookupq.processor,
    lookupq.process_id,
    lookupq.input_folder,
    lookupq.output_folder,
    lookupq.priority,
    lookupq.dependencies,
    lookupq.cpu_load,
    lookupq.tool_version_id,
    lookupq.tool_version,
    lookupq.completion_code,
    lookupq.completion_message,
    lookupq.evaluation_code,
    lookupq.evaluation_message,
    lookupq.holdoff_interval_minutes,
    lookupq.next_try,
    lookupq.retry_count,
    lookupq.instrument,
    lookupq.instrument_source_files,
    lookupq.storage_server,
    lookupq.transfer_folder_path,
    lookupq.capture_subfolder,
    lookupq.dataset_folder_path,
    lookupq.job_state,
    ((((((((lookupq.logfilepath ||
        CASE
            WHEN (EXTRACT(year FROM CURRENT_TIMESTAMP) <> EXTRACT(year FROM lookupq.start)) THEN (lookupq.theyear || '\'::text)
            ELSE ''::text
        END) || 'CapTaskMan_'::text) || lookupq.theyear) || '-'::text) || lookupq.themonth) || '-'::text) || lookupq.theday) || '.txt'::text) AS log_file_path
   FROM ( SELECT ts.job,
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
            ts.last_cpu_status_minutes,
            ts.job_progress,
            ts.runtime_predicted_hours,
            ts.processor,
            ts.process_id,
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
            ts.instrument_source_files,
            ts.storage_server,
            ts.transfer_folder_path,
            ts.dataset_folder_path,
            ts.capture_subfolder,
            ts.job_state,
            (((('\\'::text || (lp.machine)::text) || '\DMS_Programs\CaptureTaskManager'::text) ||
                CASE
                    WHEN (ts.processor OPERATOR(public.~) similar_to_escape('%[-_][1-9]'::text)) THEN "right"((ts.processor)::text, 2)
                    ELSE ''::text
                END) || '\Logs\'::text) AS logfilepath,
            to_char(EXTRACT(year FROM ts.start), 'fm0000'::text) AS theyear,
            to_char(EXTRACT(month FROM ts.start), 'fm00'::text) AS themonth,
            to_char(EXTRACT(day FROM ts.start), 'fm00'::text) AS theday
           FROM (cap.v_task_steps ts
             LEFT JOIN cap.t_local_processors lp ON ((ts.processor OPERATOR(public.=) lp.processor_name)))) lookupq;


ALTER TABLE cap.v_task_steps2 OWNER TO d3l243;

--
-- Name: TABLE v_task_steps2; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_task_steps2 TO readaccess;
GRANT SELECT ON TABLE cap.v_task_steps2 TO writeaccess;

