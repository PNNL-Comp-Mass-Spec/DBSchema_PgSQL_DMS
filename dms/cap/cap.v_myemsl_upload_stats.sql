--
-- Name: v_myemsl_upload_stats; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_myemsl_upload_stats AS
 SELECT (t_myemsl_uploads.entered)::date AS entered,
    count(t_myemsl_uploads.entry_id) AS bundles,
    sum((t_myemsl_uploads.file_count_new + t_myemsl_uploads.file_count_updated)) AS files,
    round(sum(((((t_myemsl_uploads.bytes)::numeric / 1024.0) / 1024.0) / 1024.0)), 5) AS gb
   FROM cap.t_myemsl_uploads
  WHERE ((t_myemsl_uploads.error_code = 0) AND (COALESCE(t_myemsl_uploads.status_num, 0) > 0))
  GROUP BY ((t_myemsl_uploads.entered)::date);


ALTER TABLE cap.v_myemsl_upload_stats OWNER TO d3l243;

--
-- Name: TABLE v_myemsl_upload_stats; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_myemsl_upload_stats TO readaccess;
GRANT SELECT ON TABLE cap.v_myemsl_upload_stats TO writeaccess;

