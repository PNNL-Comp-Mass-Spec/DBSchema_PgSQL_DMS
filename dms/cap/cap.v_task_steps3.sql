--
-- Name: v_task_steps3; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_task_steps3 AS
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
    js.last_cpu_status_minutes,
    js.job_progress,
    js.runtime_predicted_hours,
    js.processor,
    js.process_id,
    js.input_folder,
    js.output_folder,
    js.priority,
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
    js.storage_server,
    js.transfer_folder_path,
    js.dataset_folder_path,
    js.capture_subfolder,
    js.job_state,
    js.log_file_path,
    myemslstatus.status_uri
   FROM (cap.v_task_steps2 js
     LEFT JOIN ( SELECT v_myemsl_uploads.job,
            v_myemsl_uploads.status_uri,
            row_number() OVER (PARTITION BY v_myemsl_uploads.job ORDER BY v_myemsl_uploads.entry_id DESC) AS statusrank
           FROM cap.v_myemsl_uploads
          WHERE (NOT (v_myemsl_uploads.status_uri IS NULL))) myemslstatus ON (((js.job = myemslstatus.job) AND (myemslstatus.statusrank = 1) AND (js.tool OPERATOR(public.=) ANY (ARRAY['ArchiveVerify'::public.citext, 'DatasetArchive'::public.citext, 'ArchiveUpdate'::public.citext])))));


ALTER TABLE cap.v_task_steps3 OWNER TO d3l243;

--
-- Name: TABLE v_task_steps3; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_task_steps3 TO readaccess;

