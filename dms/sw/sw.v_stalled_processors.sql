--
-- Name: v_stalled_processors; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_stalled_processors AS
 SELECT t_local_processors.processor_id AS id,
    t_local_processors.processor_name,
    t_local_processors.state,
    t_local_processors.groups,
    t_local_processors.gp_groups,
    t_local_processors.machine,
    t_local_processors.latest_request
   FROM sw.t_local_processors
  WHERE ((t_local_processors.latest_request >= '2008-12-01 00:00:00'::timestamp without time zone) AND (t_local_processors.latest_request < (CURRENT_TIMESTAMP - '12:00:00'::interval)));


ALTER VIEW sw.v_stalled_processors OWNER TO d3l243;

--
-- Name: TABLE v_stalled_processors; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_stalled_processors TO readaccess;
GRANT SELECT ON TABLE sw.v_stalled_processors TO writeaccess;

