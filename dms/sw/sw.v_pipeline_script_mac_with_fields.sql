--
-- Name: v_pipeline_script_mac_with_fields; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_script_mac_with_fields AS
 SELECT t_scripts.script AS name,
    t_scripts.description,
    t_scripts.parameters,
    t_scripts.fields
   FROM sw.t_scripts
  WHERE ((t_scripts.enabled OPERATOR(public.=) 'Y'::public.citext) AND (t_scripts.pipeline_mac_job_enabled > 0));


ALTER VIEW sw.v_pipeline_script_mac_with_fields OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_script_mac_with_fields; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_script_mac_with_fields TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_script_mac_with_fields TO writeaccess;

