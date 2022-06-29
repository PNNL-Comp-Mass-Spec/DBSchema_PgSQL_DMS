--
-- Name: v_myemsl_upload_resets2; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_myemsl_upload_resets2 AS
 SELECT r.entry_id,
    r.job,
    r.dataset_id,
    r.subfolder,
    r.error_message,
    r.entered,
    js.step,
    js.tool,
    js.state_name,
    js.state,
    js.finish,
    js.processor,
    js.dataset,
    u.entry_id AS upload_entry_id,
    u.file_count_new,
    u.file_count_updated,
    u.mb,
    u.upload_time_seconds,
    u.status_num,
    u.error_code,
    u.status_uri,
    u.verified,
    u.ingest_steps_completed
   FROM ((cap.t_myemsl_upload_resets r
     JOIN cap.v_task_steps js ON ((r.job = js.job)))
     JOIN cap.v_myemsl_uploads u ON ((r.job = u.job)))
  WHERE (js.step = 1);


ALTER TABLE cap.v_myemsl_upload_resets2 OWNER TO d3l243;

