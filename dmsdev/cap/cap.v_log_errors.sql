--
-- Name: v_log_errors; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_log_errors AS
 SELECT entry_id,
    posted_by,
    entered,
    type,
    message,
    entered_by
   FROM cap.t_log_entries
  WHERE (type OPERATOR(public.=) 'error'::public.citext);


ALTER VIEW cap.v_log_errors OWNER TO d3l243;

--
-- Name: TABLE v_log_errors; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_log_errors TO readaccess;
GRANT SELECT ON TABLE cap.v_log_errors TO writeaccess;

