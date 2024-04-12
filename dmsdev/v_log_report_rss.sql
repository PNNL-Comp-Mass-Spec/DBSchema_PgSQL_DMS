--
-- Name: v_log_report_rss; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_log_report_rss AS
 SELECT entry AS url_title,
    (((entry)::text || ' - '::text) || (message)::text) AS post_title,
    (entry)::text AS guid,
    (((posted_by)::text || ' '::text) || (message)::text) AS post_body,
    'na'::text AS username,
    entered AS post_date
   FROM public.v_log_report
  WHERE ((type OPERATOR(public.=) 'Error'::public.citext) AND (NOT (message OPERATOR(public.~~) '%Error posting xml%'::public.citext)));


ALTER VIEW public.v_log_report_rss OWNER TO d3l243;

--
-- Name: TABLE v_log_report_rss; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_log_report_rss TO readaccess;
GRANT SELECT ON TABLE public.v_log_report_rss TO writeaccess;

