--
-- Name: v_log_entry_error_summary; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_log_entry_error_summary AS
 SELECT v_log_entry_errors.schema,
    v_log_entry_errors.posted_by,
    count(*) AS entries
   FROM public.v_log_entry_errors
  GROUP BY v_log_entry_errors.schema, v_log_entry_errors.posted_by
  ORDER BY v_log_entry_errors.schema, v_log_entry_errors.posted_by;


ALTER TABLE public.v_log_entry_error_summary OWNER TO d3l243;

--
-- Name: TABLE v_log_entry_error_summary; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_log_entry_error_summary TO readaccess;
GRANT SELECT ON TABLE public.v_log_entry_error_summary TO writeaccess;

