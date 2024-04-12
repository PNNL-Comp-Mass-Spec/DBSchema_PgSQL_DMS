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
    ts.step,
    ts.tool,
    ts.state_name,
    ts.state,
    ts.finish,
    ts.processor,
    ts.dataset,
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
     JOIN cap.v_task_steps ts ON ((r.job = ts.job)))
     JOIN cap.v_myemsl_uploads u ON ((r.job = u.job)))
  WHERE (ts.step = 1);


ALTER VIEW cap.v_myemsl_upload_resets2 OWNER TO d3l243;

--
-- Name: TABLE v_myemsl_upload_resets2; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_myemsl_upload_resets2 TO readaccess;
GRANT SELECT ON TABLE cap.v_myemsl_upload_resets2 TO writeaccess;

