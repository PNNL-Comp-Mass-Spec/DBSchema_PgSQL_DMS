--
-- Name: v_event_log_24_hour_summary; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_event_log_24_hour_summary AS
 SELECT get_event_log_summary.sortkey AS sort_key,
    get_event_log_summary.label,
    get_event_log_summary.value
   FROM public.get_event_log_summary((CURRENT_TIMESTAMP - '24:00:00'::interval), CURRENT_TIMESTAMP) get_event_log_summary(sortkey, label, value)
  ORDER BY get_event_log_summary.sortkey, get_event_log_summary.label;


ALTER TABLE public.v_event_log_24_hour_summary OWNER TO d3l243;

--
-- Name: TABLE v_event_log_24_hour_summary; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_event_log_24_hour_summary TO readaccess;
GRANT SELECT ON TABLE public.v_event_log_24_hour_summary TO writeaccess;

