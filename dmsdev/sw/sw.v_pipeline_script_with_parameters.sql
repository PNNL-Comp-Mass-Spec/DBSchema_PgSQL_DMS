--
-- Name: v_pipeline_script_with_parameters; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_script_with_parameters AS
 SELECT script
   FROM sw.t_scripts
  WHERE ((enabled OPERATOR(public.=) 'Y'::public.citext) AND (pipeline_job_enabled > 0));


ALTER VIEW sw.v_pipeline_script_with_parameters OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_script_with_parameters; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_script_with_parameters TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_script_with_parameters TO writeaccess;

