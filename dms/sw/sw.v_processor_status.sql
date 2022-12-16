--
-- Name: v_processor_status; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_processor_status AS
 SELECT ps.processor_name,
    COALESCE(ps.mgr_status, 'Unknown_Status'::public.citext) AS mgr_status,
    COALESCE(ps.task_status, 'Unknown_Status'::public.citext) AS task_status,
    COALESCE(ps.task_detail_status, 'Unknown_Status'::public.citext) AS task_detail_status,
    round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (ps.status_date)::timestamp with time zone)) / 60.0), 1) AS last_cpu_status_minutes,
    ps.job,
    ps.job_step,
    (ps.progress)::numeric(9,2) AS progress,
    (ps.duration_hours)::numeric(9,2) AS duration_hours,
        CASE
            WHEN (ps.progress > (0)::double precision) THEN round((((ps.duration_hours / (ps.progress / (100.0)::double precision)) - ps.duration_hours))::numeric, 2)
            ELSE (0)::numeric
        END AS hours_remaining,
    ps.step_tool,
    ps.dataset,
    ps.current_operation,
    ps.cpu_utilization,
    ps.free_memory_mb,
    ps.process_id,
    ps.most_recent_job_info,
    ps.most_recent_log_message,
    ps.most_recent_error_message,
    ps.status_date,
    ps.remote_manager,
    m.enabled AS machine_enabled
   FROM ((sw.t_processor_status ps
     LEFT JOIN sw.t_local_processors lp ON ((ps.processor_name OPERATOR(public.=) lp.processor_name)))
     LEFT JOIN sw.t_machines m ON ((lp.machine OPERATOR(public.=) m.machine)))
  WHERE (ps.monitor_processor <> 0);


ALTER TABLE sw.v_processor_status OWNER TO d3l243;

--
-- Name: TABLE v_processor_status; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_processor_status TO readaccess;
GRANT SELECT ON TABLE sw.v_processor_status TO writeaccess;

