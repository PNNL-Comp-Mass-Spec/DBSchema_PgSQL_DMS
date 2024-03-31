--
-- Name: v_pipeline_machines_list_report; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_machines_list_report AS
 SELECT machine,
    total_cpus,
    cpus_available
   FROM sw.t_machines;


ALTER VIEW sw.v_pipeline_machines_list_report OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_machines_list_report; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_machines_list_report TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_machines_list_report TO writeaccess;

