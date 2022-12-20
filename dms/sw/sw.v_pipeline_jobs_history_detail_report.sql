--
-- Name: v_pipeline_jobs_history_detail_report; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_jobs_history_detail_report AS
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
    j.owner,
    j.special_processing,
    j.data_pkg_id AS data_package_id,
    j.results_folder_name,
    j.imported,
    j.start,
    j.finish,
    j.runtime_minutes,
    j.transfer_folder_path,
    (jp.parameters)::text AS parameters
   FROM ((((sw.t_jobs_history j
     JOIN sw.t_job_state_name jsn ON ((j.state = jsn.job_state_id)))
     LEFT JOIN sw.t_job_parameters_history jp ON (((j.job = jp.job) AND (jp.most_recent_entry = 1))))
     LEFT JOIN ( SELECT t_job_steps_history.job,
            count(*) AS steps
           FROM sw.t_job_steps_history
          WHERE (t_job_steps_history.most_recent_entry = 1)
          GROUP BY t_job_steps_history.job) js ON ((j.job = js.job)))
     LEFT JOIN public.t_analysis_job aj ON ((j.job = aj.job)))
  WHERE (j.most_recent_entry = 1);


ALTER TABLE sw.v_pipeline_jobs_history_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_jobs_history_detail_report; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_jobs_history_detail_report TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_jobs_history_detail_report TO writeaccess;

