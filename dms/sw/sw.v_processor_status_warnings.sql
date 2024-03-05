--
-- Name: v_processor_status_warnings; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_processor_status_warnings AS
 SELECT ps.processor_name,
    COALESCE(ps.mgr_status, 'Unknown_Status'::public.citext) AS mgr_status,
    COALESCE(ps.task_status, 'Unknown_Status'::public.citext) AS task_status,
    round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (ps.status_date)::timestamp with time zone)) / (3600)::numeric), 2) AS last_status_hours,
    ps.status_date,
    ps.most_recent_job_info,
    ps.most_recent_log_message,
    ps.most_recent_error_message,
    COALESCE(ps.task_detail_status, 'Unknown_Status'::public.citext) AS task_detail_status
   FROM (sw.t_processor_status ps
     LEFT JOIN ( SELECT ps_1.processor_name,
            'Stale status'::text AS status_state
           FROM sw.t_processor_status ps_1
          WHERE ((ps_1.status_date >= (CURRENT_TIMESTAMP - '21 days'::interval)) AND (ps_1.status_date < (CURRENT_TIMESTAMP - '04:00:00'::interval)) AND (ps_1.remote_processor = 0))) staleq ON ((ps.processor_name OPERATOR(public.=) staleq.processor_name)))
  WHERE ((ps.monitor_processor > 0) AND (((ps.status_date >= (CURRENT_TIMESTAMP - '21 days'::interval)) AND (ps.mgr_status OPERATOR(public.~~) '%Error'::public.citext)) OR (ps.mgr_status OPERATOR(public.~~) 'Disabled%'::public.citext) OR (NOT (staleq.status_state IS NULL))));


ALTER VIEW sw.v_processor_status_warnings OWNER TO d3l243;

--
-- Name: TABLE v_processor_status_warnings; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_processor_status_warnings TO readaccess;
GRANT SELECT ON TABLE sw.v_processor_status_warnings TO writeaccess;

