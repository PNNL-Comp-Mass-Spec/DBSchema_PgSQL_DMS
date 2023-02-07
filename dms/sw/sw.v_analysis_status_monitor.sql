--
-- Name: v_analysis_status_monitor; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_analysis_status_monitor AS
 SELECT lp.processor_id,
    ps.processor_name,
    sw.get_processor_step_tool_list((ps.processor_name)::text) AS tools,
    ps.job,
    ps.job_step,
    ps.step_tool,
    ps.dataset,
    ps.duration_hours,
    ps.progress,
    ps.spectrum_count AS ds_scan_count,
    ps.most_recent_job_info,
    ps.most_recent_log_message,
    ps.most_recent_error_message,
    ps.status_date,
    round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (ps.status_date)::timestamp with time zone)) / 60.0), 1) AS last_cpu_status_minutes
   FROM (sw.t_local_processors lp
     RIGHT JOIN sw.t_processor_status ps ON ((lp.processor_name OPERATOR(public.=) ps.processor_name)));


ALTER TABLE sw.v_analysis_status_monitor OWNER TO d3l243;

--
-- Name: TABLE v_analysis_status_monitor; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_analysis_status_monitor TO readaccess;
GRANT SELECT ON TABLE sw.v_analysis_status_monitor TO writeaccess;

