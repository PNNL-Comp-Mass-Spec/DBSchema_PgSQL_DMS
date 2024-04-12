--
-- Name: v_myemsl_upload_resets; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_myemsl_upload_resets AS
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
    ts.dataset
   FROM (cap.t_myemsl_upload_resets r
     JOIN cap.v_task_steps ts ON ((r.job = ts.job)))
  WHERE (ts.step = 1);


ALTER VIEW cap.v_myemsl_upload_resets OWNER TO d3l243;

--
-- Name: TABLE v_myemsl_upload_resets; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_myemsl_upload_resets TO readaccess;
GRANT SELECT ON TABLE cap.v_myemsl_upload_resets TO writeaccess;

