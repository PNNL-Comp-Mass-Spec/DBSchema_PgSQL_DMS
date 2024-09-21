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
    ctl.entry_id,
    ctl.posted_by,
    ctl.entered,
    ctl.type,
    ctl.message,
    ctl.entered_by
   FROM cap.t_log_entries ctl
UNION
 SELECT 'sw'::public.citext AS schema,
    swl.entry_id,
    swl.posted_by,
    swl.entered,
    swl.type,
    swl.message,
    swl.entered_by
   FROM sw.t_log_entries swl
UNION
 SELECT 'dpkg'::public.citext AS schema,
    dpl.entry_id,
    dpl.posted_by,
    dpl.entered,
    dpl.type,
    dpl.message,
    dpl.entered_by
   FROM dpkg.t_log_entries dpl
UNION
 SELECT 'mc'::public.citext AS schema,
    mcl.entry_id,
    mcl.posted_by,
    mcl.entered,
    mcl.type,
    mcl.message,
    mcl.entered_by
   FROM mc.t_log_entries mcl
UNION
 SELECT 'pc'::public.citext AS schema,
    pcl.entry_id,
    pcl.posted_by,
    pcl.entered,
    pcl.type,
    pcl.message,
    pcl.entered_by
   FROM pc.t_log_entries pcl;


ALTER VIEW public.v_log_entries OWNER TO d3l243;

--
-- Name: TABLE v_log_entries; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_log_entries TO readaccess;
GRANT SELECT ON TABLE public.v_log_entries TO writeaccess;

