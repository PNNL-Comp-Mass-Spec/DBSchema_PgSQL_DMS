--
-- Name: v_log_entries; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_log_entries AS
 SELECT 'public'::public.citext AS schema,
    t_log_entries.entry_id,
    t_log_entries.posted_by,
    t_log_entries.entered,
    t_log_entries.type,
    t_log_entries.message,
    t_log_entries.entered_by
   FROM public.t_log_entries
UNION
 SELECT 'cap'::public.citext AS schema,
    t_log_entries.entry_id,
    t_log_entries.posted_by,
    t_log_entries.entered,
    t_log_entries.type,
    t_log_entries.message,
    t_log_entries.entered_by
   FROM cap.t_log_entries
UNION
 SELECT 'sw'::public.citext AS schema,
    t_log_entries.entry_id,
    t_log_entries.posted_by,
    t_log_entries.entered,
    t_log_entries.type,
    t_log_entries.message,
    t_log_entries.entered_by
   FROM sw.t_log_entries
UNION
 SELECT 'dpkg'::public.citext AS schema,
    t_log_entries.entry_id,
    t_log_entries.posted_by,
    t_log_entries.entered,
    t_log_entries.type,
    t_log_entries.message,
    t_log_entries.entered_by
   FROM dpkg.t_log_entries;


ALTER VIEW public.v_log_entries OWNER TO d3l243;

--
-- Name: TABLE v_log_entries; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_log_entries TO readaccess;
GRANT SELECT ON TABLE public.v_log_entries TO writeaccess;

