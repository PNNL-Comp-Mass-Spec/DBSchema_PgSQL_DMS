--
-- Name: v_pipeline_job_steps_list_report; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_job_steps_list_report AS
 SELECT js.job,
    js.step,
    j.script,
    js.tool,
    paramq.parameter_file,
    ssn.step_state,
    jsn.job_state AS job_state_b,
    j.dataset,
    js.start,
    js.finish,
        CASE
            WHEN ((js.state = 9) OR (js.remote_info_id > 1)) THEN round((EXTRACT(epoch FROM (COALESCE((js.remote_finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.remote_start)::timestamp with time zone)) / 60.0), 2)
            ELSE round((EXTRACT(epoch FROM (COALESCE((js.finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.start)::timestamp with time zone)) / 60.0), 2)
        END AS runtime_minutes,
    js.processor,
    js.state,
        CASE
            WHEN ((js.state = 9) OR (js.remote_info_id > 1)) THEN round((COALESCE(js.remote_progress, (0)::real))::numeric, 2)
            WHEN (js.state = 4) THEN round((ps.progress)::numeric, 2)
            WHEN (js.state = 5) THEN (100)::numeric
            ELSE (0)::numeric
        END AS job_progress,
        CASE
            WHEN ((js.state = 4) AND (js.tool OPERATOR(public.=) 'XTandem'::public.citext)) THEN (0)::numeric
            WHEN (((js.state = 9) OR (js.remote_info_id > 1)) AND (COALESCE(js.remote_progress, (0)::real) > (0)::double precision)) THEN round((((EXTRACT(epoch FROM (COALESCE((js.remote_finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.remote_start)::timestamp with time zone)) / ((js.remote_progress)::numeric / 100.0)) / 60.0) / 60.0), 2)
            WHEN ((js.state = 4) AND (ps.progress > (0)::double precision)) THEN round((((EXTRACT(epoch FROM (COALESCE((js.finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.start)::timestamp with time zone)) / ((ps.progress)::numeric / 100.0)) / 60.0) / 60.0), 2)
            WHEN (js.state = 5) THEN round(((EXTRACT(epoch FROM (COALESCE((js.finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.start)::timestamp with time zone)) / 60.0) / 60.0), 2)
            ELSE (0)::numeric
        END AS runtime_predicted_hours,
    round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (ps.status_date)::timestamp with time zone)) / 60.0), 1) AS last_cpu_status_minutes,
    js.input_folder_name AS input_folder,
    js.output_folder_name AS output_folder,
    j.priority,
    js.signature,
    js.cpu_load,
    js.actual_cpu_load,
    js.memory_usage_mb,
    js.tool_version_id,
    js.completion_code,
    js.completion_message,
    js.evaluation_code,
    js.evaluation_message,
    paramq.settings_file,
    ((paramq.dataset_storage_path)::text || (j.dataset)::text) AS dataset_folder_path,
    js.next_try,
    js.retry_count,
    js.remote_info_id,
    js.remote_start,
    js.remote_finish,
    js.job_plus_step AS id
   FROM (((((sw.t_job_steps js
     JOIN sw.t_job_step_state_name ssn ON ((js.state = ssn.step_state_id)))
     JOIN sw.t_jobs j ON ((js.job = j.job)))
     JOIN sw.t_job_state_name jsn ON ((j.state = jsn.job_state_id)))
     LEFT JOIN sw.t_processor_status ps ON ((js.processor OPERATOR(public.=) ps.processor_name)))
     LEFT JOIN ( SELECT src.job,
            ((xpath('//params/Param[@Name = "SettingsFileName"]/@Value'::text, src.rooted_xml))[1])::public.citext AS settings_file,
            ((xpath('//params/Param[@Name = "ParamFileName"]/@Value'::text, src.rooted_xml))[1])::public.citext AS parameter_file,
            ((xpath('//params/Param[@Name = "DatasetStoragePath"]/@Value'::text, src.rooted_xml))[1])::public.citext AS dataset_storage_path
           FROM ( SELECT t_job_parameters.job,
                    ((('<params>'::text || (t_job_parameters.parameters)::text) || '</params>'::text))::xml AS rooted_xml
                   FROM sw.t_job_parameters) src) paramq ON ((paramq.job = js.job)));


ALTER TABLE sw.v_pipeline_job_steps_list_report OWNER TO d3l243;

--
-- Name: VIEW v_pipeline_job_steps_list_report; Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON VIEW sw.v_pipeline_job_steps_list_report IS 'We cannot predict runtime for X!Tandem jobs since progress is not properly reported';

--
-- Name: TABLE v_pipeline_job_steps_list_report; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_job_steps_list_report TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_job_steps_list_report TO writeaccess;

