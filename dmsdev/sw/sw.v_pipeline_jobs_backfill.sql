--
-- Name: v_pipeline_jobs_backfill; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_jobs_backfill AS
 SELECT j.job,
    j.priority,
    j.script,
    j.state,
    j.dataset,
    j.results_folder_name,
    j.imported,
    j.start,
    j.finish,
    j.transfer_folder_path,
    j.comment,
    j.owner_username AS owner,
    jpt.processing_time_minutes,
    j.data_pkg_id
   FROM ((sw.t_jobs j
     JOIN sw.t_scripts s ON ((j.script OPERATOR(public.=) s.script)))
     JOIN sw.v_job_processing_time jpt ON ((j.job = jpt.job)))
  WHERE (s.backfill_to_dms = 1);


ALTER VIEW sw.v_pipeline_jobs_backfill OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_jobs_backfill; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_jobs_backfill TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_jobs_backfill TO writeaccess;

