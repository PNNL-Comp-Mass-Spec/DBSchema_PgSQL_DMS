--
-- Name: v_log_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_log_report AS
 SELECT t_log_entries.entry_id AS entry,
    t_log_entries.posted_by,
    t_log_entries.entered,
    t_log_entries.type,
    t_log_entries.message
   FROM public.t_log_entries;


ALTER VIEW public.v_log_report OWNER TO d3l243;

--
-- Name: TABLE v_log_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_log_report TO readaccess;
GRANT SELECT ON TABLE public.v_log_report TO writeaccess;

