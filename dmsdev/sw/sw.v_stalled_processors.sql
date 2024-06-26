--
-- Name: v_stalled_processors; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_stalled_processors AS
 SELECT processor_id AS id,
    processor_name,
    state,
    groups,
    gp_groups,
    machine,
    latest_request
   FROM sw.t_local_processors
  WHERE ((latest_request >= '2008-12-01 00:00:00'::timestamp without time zone) AND (latest_request < (CURRENT_TIMESTAMP - '12:00:00'::interval)));


ALTER VIEW sw.v_stalled_processors OWNER TO d3l243;

--
-- Name: TABLE v_stalled_processors; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_stalled_processors TO readaccess;
GRANT SELECT ON TABLE sw.v_stalled_processors TO writeaccess;

