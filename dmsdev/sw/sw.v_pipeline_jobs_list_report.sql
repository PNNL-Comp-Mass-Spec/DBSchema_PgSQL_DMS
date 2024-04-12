--
-- Name: v_pipeline_jobs_list_report; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_jobs_list_report AS
 SELECT j.job,
    j.priority,
    j.script,
    jsn.job_state AS job_state_b,
    'Steps'::text AS steps,
    j.dataset,
    j.results_folder_name,
    j.imported,
    j.start,
    j.finish,
    j.runtime_minutes,
    j.data_pkg_id,
    j.owner_username AS owner,
    j.transfer_folder_path,
    j.archive_busy,
    j.comment
   FROM (sw.t_jobs j
     JOIN sw.t_job_state_name jsn ON ((j.state = jsn.job_state_id)));


ALTER VIEW sw.v_pipeline_jobs_list_report OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_jobs_list_report; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_jobs_list_report TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_jobs_list_report TO writeaccess;

