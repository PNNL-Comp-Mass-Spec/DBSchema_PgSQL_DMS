--
-- Name: v_analysis_status_monitor2; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_analysis_status_monitor2 AS
 SELECT lp.processor_id,
    ps.processor_name,
    (sw.get_processor_step_tool_list((ps.processor_name)::text))::public.citext AS tools,
    COALESCE(ps.mgr_status, 'Unknown_Status'::public.citext) AS mgr_status,
    COALESCE(ps.task_status, 'Unknown_Status'::public.citext) AS task_status,
    COALESCE(ps.task_detail_status, 'Unknown_Status'::public.citext) AS task_detail_status,
    ps.job,
    ps.job_step,
    ps.step_tool,
    ps.dataset,
    ps.duration_hours,
    ps.progress,
    ps.spectrum_count AS ds_scan_count,
    ps.current_operation,
    ps.most_recent_job_info,
    ps.most_recent_log_message,
    ps.most_recent_error_message,
    ps.status_date,
    round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (ps.status_date)::timestamp with time zone)) / (60)::numeric), 1) AS last_cpu_status_minutes
   FROM (sw.t_local_processors lp
     RIGHT JOIN sw.t_processor_status ps ON ((lp.processor_name OPERATOR(public.=) ps.processor_name)));


ALTER VIEW sw.v_analysis_status_monitor2 OWNER TO d3l243;

--
-- Name: TABLE v_analysis_status_monitor2; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_analysis_status_monitor2 TO readaccess;
GRANT SELECT ON TABLE sw.v_analysis_status_monitor2 TO writeaccess;

