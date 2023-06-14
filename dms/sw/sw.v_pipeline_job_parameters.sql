--
-- Name: v_pipeline_job_parameters; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_job_parameters AS
 SELECT j.job,
    j.script,
    j.dataset,
    jobparams.section,
    jobparams.name AS param_name,
    jobparams.value AS param_value
   FROM ((sw.t_jobs j
     JOIN sw.t_scripts s ON ((j.script OPERATOR(public.=) s.script)))
     CROSS JOIN LATERAL sw.get_job_param_table_local(j.job) jobparams(job, section, name, value));


ALTER TABLE sw.v_pipeline_job_parameters OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_job_parameters; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_job_parameters TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_job_parameters TO writeaccess;

