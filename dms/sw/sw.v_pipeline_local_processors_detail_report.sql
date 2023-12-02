--
-- Name: v_pipeline_local_processors_detail_report; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_local_processors_detail_report AS
 SELECT t_local_processors.processor_name,
    t_local_processors.state,
    t_local_processors.groups,
    t_local_processors.gp_groups,
    t_local_processors.machine,
    t_local_processors.latest_request,
    t_local_processors.processor_id AS id
   FROM sw.t_local_processors;


ALTER VIEW sw.v_pipeline_local_processors_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_local_processors_detail_report; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_local_processors_detail_report TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_local_processors_detail_report TO writeaccess;

