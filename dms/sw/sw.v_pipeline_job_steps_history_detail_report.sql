--
-- Name: v_pipeline_job_steps_history_detail_report; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_job_steps_history_detail_report AS
 SELECT js.job_step_saved_combo AS id,
    js.job,
    js.step,
    j.dataset,
    j.script,
    js.step_tool AS tool,
    ssn.step_state,
    jsn.job_state AS job_state_b,
    js.state AS state_id,
    js.start,
    js.finish,
    round((EXTRACT(epoch FROM (COALESCE((js.finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.start)::timestamp with time zone)) / 60.0), 2) AS runtime_minutes,
    js.processor,
    js.input_folder_name AS input_folder,
    js.output_folder_name AS output_folder,
    j.priority,
    js.signature,
    0 AS cpu_load,
    0 AS actual_cpu_load,
    js.memory_usage_mb,
    js.tool_version_id,
    stv.tool_version,
    js.completion_code,
    js.completion_message,
    js.evaluation_code,
    js.evaluation_message,
    (paramq.dataset_storage_path || (j.dataset)::text) AS dataset_folder_path,
    j.transfer_folder_path
   FROM (((((sw.t_job_steps_history js
     JOIN sw.t_job_step_state_name ssn ON ((js.state = ssn.step_state_id)))
     JOIN ( SELECT t_jobs_history.job,
            t_jobs_history.dataset,
            t_jobs_history.script,
            t_jobs_history.state,
            t_jobs_history.priority,
            t_jobs_history.transfer_folder_path
           FROM sw.t_jobs_history
          WHERE (t_jobs_history.most_recent_entry = 1)) j ON ((js.job = j.job)))
     JOIN sw.t_job_state_name jsn ON ((j.state = jsn.job_state_id)))
     LEFT JOIN ( SELECT src.job,
            ((xpath('//params/Param[@Name = "SettingsFileName"]/@Value'::text, src.rooted_xml))[1])::text AS settings_file,
            ((xpath('//params/Param[@Name = "ParamFileName"]/@Value'::text, src.rooted_xml))[1])::text AS parameter_file,
            ((xpath('//params/Param[@Name = "DatasetStoragePath"]/@Value'::text, src.rooted_xml))[1])::text AS dataset_storage_path
           FROM ( SELECT t_job_parameters_history.job,
                    ((('<params>'::text || (t_job_parameters_history.parameters)::text) || '</params>'::text))::xml AS rooted_xml
                   FROM sw.t_job_parameters_history
                  WHERE (t_job_parameters_history.most_recent_entry = 1)) src) paramq ON ((paramq.job = js.job)))
     LEFT JOIN sw.t_step_tool_versions stv ON ((js.tool_version_id = stv.tool_version_id)))
  WHERE (js.most_recent_entry = 1);


ALTER TABLE sw.v_pipeline_job_steps_history_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_job_steps_history_detail_report; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_job_steps_history_detail_report TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_job_steps_history_detail_report TO writeaccess;

