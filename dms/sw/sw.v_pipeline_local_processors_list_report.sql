--
-- Name: v_pipeline_local_processors_list_report; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_local_processors_list_report AS
 SELECT processor_name,
    state,
    groups,
    gp_groups,
    machine,
    latest_request,
    processor_id AS id
   FROM sw.t_local_processors;


ALTER VIEW sw.v_pipeline_local_processors_list_report OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_local_processors_list_report; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_local_processors_list_report TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_local_processors_list_report TO writeaccess;

