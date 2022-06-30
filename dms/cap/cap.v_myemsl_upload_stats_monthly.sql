--
-- Name: v_myemsl_upload_stats_monthly; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_myemsl_upload_stats_monthly AS
 SELECT EXTRACT(year FROM t_myemsl_uploads.entered) AS year,
    EXTRACT(month FROM t_myemsl_uploads.entered) AS month,
    count(*) AS bundles,
    sum((t_myemsl_uploads.file_count_new + t_myemsl_uploads.file_count_updated)) AS files,
    round(sum((((((t_myemsl_uploads.bytes)::numeric / 1024.0) / 1024.0) / 1024.0) / 1024.0)), 5) AS tb
   FROM cap.t_myemsl_uploads
  WHERE ((t_myemsl_uploads.error_code = 0) AND (COALESCE(t_myemsl_uploads.status_num, 0) > 0))
  GROUP BY (EXTRACT(year FROM t_myemsl_uploads.entered)), (EXTRACT(month FROM t_myemsl_uploads.entered));


ALTER TABLE cap.v_myemsl_upload_stats_monthly OWNER TO d3l243;

