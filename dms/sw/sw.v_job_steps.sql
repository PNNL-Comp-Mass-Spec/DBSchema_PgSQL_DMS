--
-- Name: v_job_steps; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_steps AS
 SELECT js.job,
    js.dataset,
    js.step,
    js.script,
    js.tool,
    js.state_name,
    js.state,
    js.start,
    js.finish,
    js.runtime_minutes,
    ((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (ps.status_date)::timestamp with time zone)) / 60.0))::integer AS last_cpu_status_minutes,
        CASE
            WHEN ((js.state = 9) OR (js.retry_count > 0)) THEN js.remote_progress
            WHEN (js.state = 4) THEN ps.progress
            WHEN (js.state = ANY (ARRAY[3, 5])) THEN (100)::real
            ELSE (0)::real
        END AS job_progress,
        CASE
            WHEN (((js.state = 9) OR (js.retry_count > 0)) AND (js.remote_progress > (0)::double precision)) THEN round(((((js.runtime_minutes)::double precision / (js.remote_progress / (100.0)::double precision)) / (60.0)::double precision))::numeric, 2)
            WHEN ((js.state = 4) AND (js.tool OPERATOR(public.=) 'XTandem'::public.citext)) THEN (0)::numeric
            WHEN ((js.state = 4) AND (ps.progress > (0)::double precision)) THEN round(((((js.runtime_minutes)::double precision / (ps.progress / (100.0)::double precision)) / (60.0)::double precision))::numeric, 2)
            WHEN (js.state = 5) THEN round((js.runtime_minutes / 60.0), 2)
            ELSE (0)::numeric
        END AS runtime_predicted_hours,
    js.processor,
        CASE
            WHEN (js.state = 4) THEN ps.process_id
            ELSE NULL::integer
        END AS process_id,
        CASE
            WHEN (js.state = 4) THEN ps.prog_runner_process_id
            ELSE NULL::integer
        END AS prog_runner_process_id,
        CASE
            WHEN (js.state = 4) THEN ps.prog_runner_core_usage
            ELSE NULL::real
        END AS prog_runner_core_usage,
        CASE
            WHEN ((js.state = 4) AND (NOT ((ps.job = js.job) AND (ps.job_step = js.step)))) THEN ((('Error, running job '::text || ((ps.job)::character varying(12))::text) || ', step '::text) || ((ps.job_step)::character varying(9))::text)
            ELSE ''::text
        END AS processor_warning,
    js.input_folder,
    js.output_folder,
    js.priority,
    js.signature,
    js.dependencies,
    js.cpu_load,
    js.actual_cpu_load,
    js.memory_usage_mb,
    js.tool_version_id,
    js.tool_version,
    js.completion_code,
    js.completion_message,
    js.evaluation_code,
    js.evaluation_message,
    js.next_try,
    js.retry_count,
    js.remote_info_id,
    js.remote_info,
    js.remote_timestamp,
    js.remote_start,
    js.remote_finish,
    js.remote_progress,
    js.dataset_id,
    js.data_pkg_id,
    js.transfer_folder_path,
    (((('\\'::text || (lp.machine)::text) || '\DMS_Programs\AnalysisToolManager'::text) ||
        CASE
            WHEN (js.processor OPERATOR(public.~) similar_to_escape('%-[1-9]'::text)) THEN "right"((js.processor)::text, 1)
            ELSE ''::text
        END) || '\Logs\'::text) AS log_file_path
   FROM ((( SELECT jobsteps.job,
            j.dataset,
            j.dataset_id,
            j.data_pkg_id,
            jobsteps.step,
            s.script,
            jobsteps.tool,
            ssn.step_state AS state_name,
            jobsteps.state,
                CASE
                    WHEN ((jobsteps.state <> 4) AND (NOT (jobsteps.remote_start IS NULL))) THEN jobsteps.remote_start
                    ELSE jobsteps.start
                END AS start,
                CASE
                    WHEN ((jobsteps.state <> 4) AND (NOT (jobsteps.remote_start IS NULL))) THEN jobsteps.remote_finish
                    ELSE jobsteps.finish
                END AS finish,
                CASE
                    WHEN (((jobsteps.state = 9) OR (jobsteps.retry_count > 0)) AND (NOT (jobsteps.remote_start IS NULL))) THEN round((EXTRACT(epoch FROM (COALESCE((jobsteps.remote_finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (jobsteps.remote_start)::timestamp with time zone)) / 60.0), 1)
                    ELSE round((EXTRACT(epoch FROM (COALESCE((jobsteps.finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (jobsteps.start)::timestamp with time zone)) / 60.0), 1)
                END AS runtime_minutes,
            jobsteps.processor,
            jobsteps.input_folder_name AS input_folder,
            jobsteps.output_folder_name AS output_folder,
            j.priority,
            jobsteps.signature,
            jobsteps.dependencies,
            jobsteps.cpu_load,
            jobsteps.actual_cpu_load,
            jobsteps.memory_usage_mb,
            jobsteps.completion_code,
            jobsteps.completion_message,
            jobsteps.evaluation_code,
            jobsteps.evaluation_message,
            jobsteps.next_try,
            jobsteps.retry_count,
            jobsteps.remote_info_id,
            ri.remote_info,
            jobsteps.remote_timestamp,
            jobsteps.remote_start,
            jobsteps.remote_finish,
            jobsteps.remote_progress,
            j.transfer_folder_path,
            jobsteps.tool_version_id,
            stv.tool_version
           FROM (((((sw.t_job_steps jobsteps
             JOIN sw.t_job_step_state_name ssn ON ((jobsteps.state = ssn.step_state_id)))
             JOIN sw.t_jobs j ON ((jobsteps.job = j.job)))
             JOIN sw.t_scripts s ON ((j.script OPERATOR(public.=) s.script)))
             LEFT JOIN sw.t_step_tool_versions stv ON ((jobsteps.tool_version_id = stv.tool_version_id)))
             LEFT JOIN sw.t_remote_info ri ON ((jobsteps.remote_info_id = ri.remote_info_id)))) js
     LEFT JOIN sw.t_processor_status ps ON ((js.processor OPERATOR(public.=) ps.processor_name)))
     LEFT JOIN sw.t_local_processors lp ON ((js.processor OPERATOR(public.=) lp.processor_name)));


ALTER TABLE sw.v_job_steps OWNER TO d3l243;

--
-- Name: VIEW v_job_steps; Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON VIEW sw.v_job_steps IS 'We cannot predict runtime for X!Tandem jobs since progress is not properly reported';

--
-- Name: TABLE v_job_steps; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_steps TO readaccess;
GRANT SELECT ON TABLE sw.v_job_steps TO writeaccess;

