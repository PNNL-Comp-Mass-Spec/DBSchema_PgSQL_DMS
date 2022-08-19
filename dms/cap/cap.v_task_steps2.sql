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
   FROM ( SELECT js.job,
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
            js.last_cpu_status_minutes,
            js.job_progress,
            js.runtime_predicted_hours,
            js.processor,
            js.process_id,
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
            js.instrument_source_files,
            js.storage_server,
            js.transfer_folder_path,
            js.dataset_folder_path,
            js.capture_subfolder,
            js.job_state,
            (((('\\'::text || (lp.machine)::text) || '\DMS_Programs\CaptureTaskManager'::text) ||
                CASE
                    WHEN (js.processor OPERATOR(public.~) similar_to_escape('%[-_][1-9]'::text)) THEN "right"((js.processor)::text, 2)
                    ELSE ''::text
                END) || '\Logs\'::text) AS logfilepath,
            to_char(EXTRACT(year FROM js.start), 'fm0000'::text) AS theyear,
            to_char(EXTRACT(month FROM js.start), 'fm00'::text) AS themonth,
            to_char(EXTRACT(day FROM js.start), 'fm00'::text) AS theday
           FROM (cap.v_task_steps js
             LEFT JOIN cap.t_local_processors lp ON ((js.processor OPERATOR(public.=) lp.processor_name)))) lookupq;


ALTER TABLE cap.v_task_steps2 OWNER TO d3l243;

--
-- Name: TABLE v_task_steps2; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_task_steps2 TO readaccess;
GRANT SELECT ON TABLE cap.v_task_steps2 TO writeaccess;

