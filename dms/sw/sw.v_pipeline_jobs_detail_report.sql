--
-- Name: v_pipeline_jobs_detail_report; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_jobs_detail_report AS
 SELECT j.job,
    j.priority,
    j.script,
    jsn.job_state,
    j.state AS job_state_id,
    COALESCE(js.steps, (0)::bigint) AS steps,
    j.dataset,
    aj.settings_file_name AS settings_file,
    aj.param_file_name AS parameter_file,
    j.comment,
    j.owner_username AS owner,
    j.special_processing,
    j.data_pkg_id AS data_package_id,
    j.results_folder_name,
    j.imported,
    j.start,
    j.finish,
    j.runtime_minutes,
    j.transfer_folder_path,
    j.archive_busy,
    (jp.parameters)::text AS parameters
   FROM ((((sw.t_jobs j
     JOIN sw.t_job_state_name jsn ON ((j.state = jsn.job_state_id)))
     JOIN sw.t_job_parameters jp ON ((j.job = jp.job)))
     LEFT JOIN ( SELECT t_job_steps.job,
            count(t_job_steps.step) AS steps
           FROM sw.t_job_steps
          GROUP BY t_job_steps.job) js ON ((j.job = js.job)))
     LEFT JOIN public.t_analysis_job aj ON ((j.job = aj.job)));


ALTER TABLE sw.v_pipeline_jobs_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_jobs_detail_report; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_jobs_detail_report TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_jobs_detail_report TO writeaccess;

