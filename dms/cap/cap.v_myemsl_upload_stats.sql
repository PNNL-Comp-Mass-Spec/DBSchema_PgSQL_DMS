--
-- Name: v_myemsl_upload_stats; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_myemsl_upload_stats AS
 SELECT (entered)::date AS entered,
    count(entry_id) AS bundles,
    sum((file_count_new + file_count_updated)) AS files,
    round(sum(((((bytes)::numeric / 1024.0) / 1024.0) / 1024.0)), 5) AS gb
   FROM cap.t_myemsl_uploads
  WHERE ((error_code = 0) AND (COALESCE(status_num, 0) > 0))
  GROUP BY ((entered)::date);


ALTER VIEW cap.v_myemsl_upload_stats OWNER TO d3l243;

--
-- Name: TABLE v_myemsl_upload_stats; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_myemsl_upload_stats TO readaccess;
GRANT SELECT ON TABLE cap.v_myemsl_upload_stats TO writeaccess;

