--
-- Name: v_pipeline_jobs_entry; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_jobs_entry AS
 SELECT j.job,
    j.priority,
    j.script AS script_name,
    j.dataset,
    j.results_folder_name,
    j.comment,
    j.owner AS owner_prn,
    j.data_pkg_id AS data_package_id,
    (jp.parameters)::text AS job_param
   FROM (sw.t_jobs j
     JOIN sw.t_job_parameters jp ON ((j.job = jp.job)));


ALTER TABLE sw.v_pipeline_jobs_entry OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_jobs_entry; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_jobs_entry TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_jobs_entry TO writeaccess;

