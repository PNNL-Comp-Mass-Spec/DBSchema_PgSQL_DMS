--
-- Name: v_pipeline_scripts_enabled; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_scripts_enabled AS
 SELECT script
   FROM sw.t_scripts
  WHERE ((enabled OPERATOR(public.=) 'Y'::public.citext) AND (pipeline_job_enabled > 0));


ALTER VIEW sw.v_pipeline_scripts_enabled OWNER TO d3l243;

--
-- Name: VIEW v_pipeline_scripts_enabled; Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON VIEW sw.v_pipeline_scripts_enabled IS 'This view is used by DMS website page families pipeline_jobs and pipeline_jobs_history in the utility_queries section';

--
-- Name: TABLE v_pipeline_scripts_enabled; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_scripts_enabled TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_scripts_enabled TO writeaccess;

