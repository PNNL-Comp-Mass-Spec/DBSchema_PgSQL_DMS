--
-- Name: v_log_report_rss; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_log_report_rss AS
 SELECT v_log_report.entry AS url_title,
    (((v_log_report.entry)::text || ' - '::text) || (v_log_report.message)::text) AS post_title,
    (v_log_report.entry)::text AS guid,
    (((v_log_report.posted_by)::text || ' '::text) || (v_log_report.message)::text) AS post_body,
    'na'::text AS username,
    v_log_report.entered AS post_date
   FROM public.v_log_report
  WHERE ((v_log_report.type OPERATOR(public.=) 'Error'::public.citext) AND (NOT (v_log_report.message OPERATOR(public.~~) '%Error posting xml%'::public.citext)));


ALTER TABLE public.v_log_report_rss OWNER TO d3l243;

--
-- Name: TABLE v_log_report_rss; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_log_report_rss TO readaccess;
GRANT SELECT ON TABLE public.v_log_report_rss TO writeaccess;

