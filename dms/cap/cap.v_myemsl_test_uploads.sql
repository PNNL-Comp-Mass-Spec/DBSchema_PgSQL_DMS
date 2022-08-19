--
-- Name: v_myemsl_test_uploads; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_myemsl_test_uploads AS
 SELECT mu.entry_id,
    mu.job,
    ds.dataset,
    mu.dataset_id,
    mu.subfolder,
    mu.file_count_new,
    mu.file_count_updated,
    round((((mu.bytes)::numeric / 1024.0) / 1024.0), 3) AS mb,
    round((mu.upload_time_seconds)::numeric, 1) AS upload_time_seconds,
    mu.status_uri_path_id,
    mu.status_num,
    mu.error_code,
    (((statusu.uri_path)::text || (mu.status_num)::text) ||
        CASE
            WHEN (statusu.uri_path OPERATOR(public.~~) '%/status/%'::public.citext) THEN '/xml'::text
            ELSE ''::text
        END) AS status_uri,
    mu.verified,
    mu.ingest_steps_completed,
    mu.entered
   FROM ((cap.t_myemsl_test_uploads mu
     LEFT JOIN cap.t_uri_paths statusu ON ((mu.status_uri_path_id = statusu.uri_path_id)))
     LEFT JOIN public.t_dataset ds ON ((mu.dataset_id = ds.dataset_id)));


ALTER TABLE cap.v_myemsl_test_uploads OWNER TO d3l243;

--
-- Name: TABLE v_myemsl_test_uploads; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_myemsl_test_uploads TO readaccess;

