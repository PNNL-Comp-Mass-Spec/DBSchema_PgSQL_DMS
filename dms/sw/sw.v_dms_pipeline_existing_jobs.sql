--
-- Name: v_dms_pipeline_existing_jobs; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_dms_pipeline_existing_jobs AS
 SELECT t_analysis_job.job,
    t_analysis_job.job_state_id AS state
   FROM public.t_analysis_job;


ALTER VIEW sw.v_dms_pipeline_existing_jobs OWNER TO d3l243;

--
-- Name: TABLE v_dms_pipeline_existing_jobs; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_dms_pipeline_existing_jobs TO readaccess;
GRANT SELECT ON TABLE sw.v_dms_pipeline_existing_jobs TO writeaccess;

