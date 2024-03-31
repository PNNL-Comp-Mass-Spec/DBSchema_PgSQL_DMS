--
-- Name: v_log_errors; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_log_errors AS
 SELECT entry_id,
    posted_by,
    entered,
    type,
    message,
    entered_by
   FROM public.t_log_entries
  WHERE (type OPERATOR(public.=) 'Error'::public.citext);


ALTER VIEW public.v_log_errors OWNER TO d3l243;

--
-- Name: TABLE v_log_errors; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_log_errors TO readaccess;
GRANT SELECT ON TABLE public.v_log_errors TO writeaccess;

