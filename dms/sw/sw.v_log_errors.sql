--
-- Name: v_log_errors; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_log_errors AS
 SELECT t_log_entries.entry_id,
    t_log_entries.posted_by,
    t_log_entries.posting_time,
    t_log_entries.type,
    t_log_entries.message,
    t_log_entries.entered_by
   FROM sw.t_log_entries
  WHERE (t_log_entries.type OPERATOR(public.=) 'error'::public.citext);


ALTER TABLE sw.v_log_errors OWNER TO d3l243;

--
-- Name: TABLE v_log_errors; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_log_errors TO readaccess;

