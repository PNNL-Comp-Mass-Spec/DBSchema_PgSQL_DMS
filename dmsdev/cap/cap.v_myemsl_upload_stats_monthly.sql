--
-- Name: v_myemsl_upload_stats_monthly; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_myemsl_upload_stats_monthly AS
 SELECT EXTRACT(year FROM entered) AS year,
    EXTRACT(month FROM entered) AS month,
    count(entry_id) AS bundles,
    sum((file_count_new + file_count_updated)) AS files,
    round(sum((((((bytes)::numeric / 1024.0) / 1024.0) / 1024.0) / 1024.0)), 5) AS tb
   FROM cap.t_myemsl_uploads
  WHERE ((error_code = 0) AND (COALESCE(status_num, 0) > 0))
  GROUP BY (EXTRACT(year FROM entered)), (EXTRACT(month FROM entered));


ALTER VIEW cap.v_myemsl_upload_stats_monthly OWNER TO d3l243;

--
-- Name: TABLE v_myemsl_upload_stats_monthly; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_myemsl_upload_stats_monthly TO readaccess;
GRANT SELECT ON TABLE cap.v_myemsl_upload_stats_monthly TO writeaccess;

