--
-- Name: v_pipeline_jobs_active_or_complete; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_jobs_active_or_complete AS
 SELECT j.job,
    j.priority,
    j.script,
    j.state,
    jsn.job_state AS state_name,
    j.dataset,
    j.dataset_id,
    j.storage_server,
    j.imported,
    j.start,
    j.finish,
    sum(
        CASE
            WHEN (js.state = ANY (ARRAY[2, 4, 5])) THEN 1
            ELSE 0
        END) AS step_count_active_or_complete
   FROM ((sw.t_jobs j
     JOIN sw.t_job_state_name jsn ON ((j.state = jsn.job_state_id)))
     LEFT JOIN sw.t_job_steps js ON ((j.job = js.job)))
  WHERE ((j.state = ANY (ARRAY[0, 1, 2, 3, 7, 8, 9, 14, 20])) OR (js.state = ANY (ARRAY[2, 4, 5])))
  GROUP BY j.job, j.priority, j.script, j.state, jsn.job_state, j.dataset, j.dataset_id, j.storage_server, j.results_folder_name, j.imported, j.start, j.finish;


ALTER TABLE sw.v_pipeline_jobs_active_or_complete OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_jobs_active_or_complete; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_jobs_active_or_complete TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_jobs_active_or_complete TO writeaccess;

