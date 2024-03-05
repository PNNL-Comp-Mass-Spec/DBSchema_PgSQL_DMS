--
-- Name: v_analysis_status_monitor; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_analysis_status_monitor AS
 SELECT COALESCE(asm.id, lp.processor_id) AS id,
    COALESCE(asm.name, ps.processor_name) AS name,
        CASE
            WHEN (asm.name IS NULL) THEN sw.get_processor_step_tool_list((ps.processor_name)::text)
            ELSE
            CASE
                WHEN (sw.get_processor_step_tool_list((asm.name)::text) = ''::text) THEN asm.tools
                ELSE sw.get_processor_step_tool_list((asm.name)::text)
            END
        END AS tools,
    COALESCE(asm.enabled_groups, ''::text) AS enabled_groups,
    COALESCE(asm.disabled_groups, ''::text) AS disabled_groups,
    COALESCE(asm.status_file_name_path, ''::public.citext) AS status_file_name_path,
    COALESCE((asm.check_box_state)::integer, 1) AS check_box_state,
    COALESCE((asm.use_for_status_check)::integer, 1) AS use_for_status_check,
    COALESCE(ps.mgr_status, 'Unknown_Status'::public.citext) AS status_name,
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
    round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (ps.status_date)::timestamp with time zone)) / 60), 1) AS last_cpu_status_minutes
   FROM ((sw.t_local_processors lp
     RIGHT JOIN sw.t_processor_status ps ON ((lp.processor_name OPERATOR(public.=) ps.processor_name)))
     FULL JOIN public.v_analysis_status_monitor asm ON ((ps.processor_name OPERATOR(public.=) asm.name)))
  WHERE (COALESCE((asm.use_for_status_check)::integer, 1) > 0);


ALTER TABLE sw.v_analysis_status_monitor OWNER TO d3l243;

--
-- Name: TABLE v_analysis_status_monitor; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_analysis_status_monitor TO readaccess;
GRANT SELECT ON TABLE sw.v_analysis_status_monitor TO writeaccess;

