--
-- Name: v_log_errors; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_log_errors AS
 SELECT entry_id,
    posted_by,
    entered,
    type,
    message,
    entered_by
   FROM sw.t_log_entries
  WHERE (type OPERATOR(public.=) 'error'::public.citext);


ALTER VIEW sw.v_log_errors OWNER TO d3l243;

--
-- Name: TABLE v_log_errors; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_log_errors TO readaccess;
GRANT SELECT ON TABLE sw.v_log_errors TO writeaccess;

