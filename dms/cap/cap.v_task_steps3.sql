--
-- Name: v_task_steps3; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_task_steps3 AS
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
    ts.last_cpu_status_minutes,
    ts.job_progress,
    ts.runtime_predicted_hours,
    ts.processor,
    ts.process_id,
    ts.input_folder,
    ts.output_folder,
    ts.priority,
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
    ts.storage_server,
    ts.transfer_folder_path,
    ts.dataset_folder_path,
    ts.capture_subfolder,
    ts.job_state,
    ts.log_file_path,
    myemslstatus.status_uri
   FROM (cap.v_task_steps2 ts
     LEFT JOIN ( SELECT v_myemsl_uploads.job,
            v_myemsl_uploads.status_uri,
            row_number() OVER (PARTITION BY v_myemsl_uploads.job ORDER BY v_myemsl_uploads.entry_id DESC) AS statusrank
           FROM cap.v_myemsl_uploads
          WHERE (NOT (v_myemsl_uploads.status_uri IS NULL))) myemslstatus ON (((ts.job = myemslstatus.job) AND (myemslstatus.statusrank = 1) AND (ts.tool OPERATOR(public.=) ANY (ARRAY['ArchiveVerify'::public.citext, 'DatasetArchive'::public.citext, 'ArchiveUpdate'::public.citext])))));


ALTER VIEW cap.v_task_steps3 OWNER TO d3l243;

--
-- Name: TABLE v_task_steps3; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_task_steps3 TO readaccess;
GRANT SELECT ON TABLE cap.v_task_steps3 TO writeaccess;

