--
-- Name: v_log_entry_errors; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_log_entry_errors AS
 SELECT 'public'::text AS schema,
    t_log_entries.entry_id,
    t_log_entries.posted_by,
    t_log_entries.entered,
    t_log_entries.type,
    t_log_entries.message,
    t_log_entries.entered_by
   FROM public.t_log_entries
  WHERE (t_log_entries.type OPERATOR(public.=) 'Error'::public.citext)
UNION
 SELECT 'cap'::text AS schema,
    t_log_entries.entry_id,
    t_log_entries.posted_by,
    t_log_entries.entered,
    t_log_entries.type,
    t_log_entries.message,
    t_log_entries.entered_by
   FROM cap.t_log_entries
  WHERE (t_log_entries.type OPERATOR(public.=) 'Error'::public.citext)
UNION
 SELECT 'sw'::text AS schema,
    t_log_entries.entry_id,
    t_log_entries.posted_by,
    t_log_entries.entered,
    t_log_entries.type,
    t_log_entries.message,
    t_log_entries.entered_by
   FROM sw.t_log_entries
  WHERE (t_log_entries.type OPERATOR(public.=) 'Error'::public.citext)
UNION
 SELECT 'dpkg'::text AS schema,
    t_log_entries.entry_id,
    t_log_entries.posted_by,
    t_log_entries.entered,
    t_log_entries.type,
    t_log_entries.message,
    t_log_entries.entered_by
   FROM dpkg.t_log_entries
  WHERE (t_log_entries.type OPERATOR(public.=) 'Error'::public.citext)
UNION
 SELECT 'mc'::text AS schema,
    t_log_entries.entry_id,
    t_log_entries.posted_by,
    t_log_entries.entered,
    t_log_entries.type,
    t_log_entries.message,
    t_log_entries.entered_by
   FROM mc.t_log_entries
  WHERE (t_log_entries.type OPERATOR(public.=) 'Error'::public.citext)
UNION
 SELECT 'pc'::text AS schema,
    t_log_entries.entry_id,
    t_log_entries.posted_by,
    t_log_entries.entered,
    t_log_entries.type,
    t_log_entries.message,
    t_log_entries.entered_by
   FROM pc.t_log_entries
  WHERE (t_log_entries.type OPERATOR(public.=) 'Error'::public.citext);


ALTER TABLE public.v_log_entry_errors OWNER TO d3l243;

--
-- Name: TABLE v_log_entry_errors; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_log_entry_errors TO readaccess;
GRANT SELECT ON TABLE public.v_log_entry_errors TO writeaccess;

