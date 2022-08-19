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
    js.step,
    js.tool,
    js.state_name,
    js.state,
    js.finish,
    js.processor,
    js.dataset
   FROM (cap.t_myemsl_upload_resets r
     JOIN cap.v_task_steps js ON ((r.job = js.job)))
  WHERE (js.step = 1);


ALTER TABLE cap.v_myemsl_upload_resets OWNER TO d3l243;

--
-- Name: TABLE v_myemsl_upload_resets; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_myemsl_upload_resets TO readaccess;

