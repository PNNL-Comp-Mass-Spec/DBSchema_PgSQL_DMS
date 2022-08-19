--
-- Name: v_myemsl_job_counts_by_instrument; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_myemsl_job_counts_by_instrument AS
 SELECT t_tasks.instrument,
    round(sum(((((t_myemsl_uploads.bytes)::numeric / 1024.0) / 1024.0) / 1024.0)), 1) AS gb,
    count(*) AS upload_count
   FROM (cap.t_myemsl_uploads
     JOIN cap.t_tasks ON ((t_myemsl_uploads.job = t_tasks.job)))
  WHERE (t_myemsl_uploads.error_code = 0)
  GROUP BY t_tasks.instrument;


ALTER TABLE cap.v_myemsl_job_counts_by_instrument OWNER TO d3l243;

--
-- Name: TABLE v_myemsl_job_counts_by_instrument; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_myemsl_job_counts_by_instrument TO readaccess;

