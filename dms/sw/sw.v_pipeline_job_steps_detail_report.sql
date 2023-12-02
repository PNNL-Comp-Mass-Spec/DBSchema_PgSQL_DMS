--
-- Name: v_pipeline_job_steps_detail_report; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_job_steps_detail_report AS
 SELECT js.job_plus_step AS id,
    js.job,
    js.step,
    j.dataset,
    j.script,
    js.tool,
    ssn.step_state,
    jsn.job_state AS job_state_b,
    js.state AS state_id,
    js.start,
    js.finish,
        CASE
            WHEN ((js.state = 9) OR (js.remote_info_id > 1)) THEN round((EXTRACT(epoch FROM (COALESCE((js.remote_finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.remote_start)::timestamp with time zone)) / 60.0), 2)
            ELSE round((EXTRACT(epoch FROM (COALESCE((js.finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.start)::timestamp with time zone)) / 60.0), 2)
        END AS runtime_minutes,
        CASE
            WHEN ((js.state = ANY (ARRAY[4, 9])) AND (js.remote_info_id > 1)) THEN ((round(COALESCE((js.remote_progress)::numeric, (0)::numeric), 2))::text || '% complete'::text)
            WHEN (js.state = 4) THEN ((round(COALESCE((ps.progress)::numeric, (0)::numeric), 2))::text || '% complete'::text)
            WHEN (js.state = 5) THEN 'Complete'::text
            ELSE 'Not started'::text
        END AS job_progress,
        CASE
            WHEN ((js.state = 4) AND (js.tool OPERATOR(public.=) 'XTandem'::public.citext)) THEN (0)::numeric
            WHEN (((js.state = 9) OR (js.remote_info_id > 1)) AND (COALESCE(js.remote_progress, (0)::real) > (0)::double precision)) THEN round((((EXTRACT(epoch FROM (COALESCE((js.remote_finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.remote_start)::timestamp with time zone)) / ((js.remote_progress)::numeric / 100.0)) / 60.0) / 60.0), 2)
            WHEN ((js.state = 4) AND (ps.progress > (0)::double precision)) THEN round((((EXTRACT(epoch FROM (COALESCE((js.finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.start)::timestamp with time zone)) / ((ps.progress)::numeric / 100.0)) / 60.0) / 60.0), 2)
            WHEN (js.state = 5) THEN round(((EXTRACT(epoch FROM (COALESCE((js.finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.start)::timestamp with time zone)) / 60.0) / 60.0), 2)
            ELSE (0)::numeric
        END AS runtime_predicted_hours,
    js.processor,
    js.input_folder_name AS input_folder,
    js.output_folder_name AS output_folder,
    j.priority,
    js.signature,
    js.cpu_load,
    js.actual_cpu_load,
    js.memory_usage_mb,
    js.tool_version_id,
    stv.tool_version,
    js.completion_code,
    js.completion_message,
    js.evaluation_code,
    js.evaluation_message,
    js2.dataset_folder_path,
    j.transfer_folder_path,
    js2.log_file_path,
    js.next_try,
    js.retry_count,
    js.remote_info_id,
    replace(public.replace(ri.remote_info, '<'::public.citext, '&lt;'::public.citext), '>'::text, '&gt;'::text) AS remote_info,
    js.remote_start,
    js.remote_finish
   FROM (((((((sw.t_job_steps js
     JOIN sw.t_job_step_state_name ssn ON ((js.state = ssn.step_state_id)))
     JOIN sw.t_jobs j ON ((js.job = j.job)))
     JOIN sw.t_job_state_name jsn ON ((j.state = jsn.job_state_id)))
     JOIN sw.v_job_steps2 js2 ON (((js.job = js2.job) AND (js.step = js2.step))))
     LEFT JOIN sw.t_step_tool_versions stv ON ((js.tool_version_id = stv.tool_version_id)))
     LEFT JOIN sw.t_processor_status ps ON ((js.processor OPERATOR(public.=) ps.processor_name)))
     LEFT JOIN sw.t_remote_info ri ON ((ri.remote_info_id = js.remote_info_id)));


ALTER VIEW sw.v_pipeline_job_steps_detail_report OWNER TO d3l243;

--
-- Name: VIEW v_pipeline_job_steps_detail_report; Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON VIEW sw.v_pipeline_job_steps_detail_report IS 'runtime_predicted_hours is 0 for X!Tandem jobs since progress is not properly reported';

--
-- Name: TABLE v_pipeline_job_steps_detail_report; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_job_steps_detail_report TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_job_steps_detail_report TO writeaccess;

