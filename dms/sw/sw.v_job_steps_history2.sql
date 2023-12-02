--
-- Name: v_job_steps_history2; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_steps_history2 AS
 SELECT js.job,
    j.dataset,
    js.step,
    s.script,
    js.tool,
    paramq.settings_file,
    paramq.parameter_file,
    ssn.step_state AS state_name,
    js.state,
    js.start,
    js.finish,
        CASE
            WHEN ((js.remote_info_id > 1) AND (NOT (js.remote_start IS NULL))) THEN round((EXTRACT(epoch FROM (COALESCE((js.remote_finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.remote_start)::timestamp with time zone)) / 60.0), 1)
            WHEN (NOT (js.finish IS NULL)) THEN round((EXTRACT(epoch FROM (COALESCE((js.finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.start)::timestamp with time zone)) / 60.0), 1)
            ELSE NULL::numeric
        END AS runtime_minutes,
    js.processor,
    js.input_folder_name AS input_folder,
    js.output_folder_name AS output_folder,
    j.priority,
    js.signature,
    js.tool_version_id,
    stv.tool_version,
    js.completion_code,
    js.completion_message,
    js.evaluation_code,
    js.evaluation_message,
    js.remote_info_id,
    ri.remote_info,
    js.remote_start,
    js.remote_finish,
    j.dataset_id,
    lp.machine,
    js.saved,
    js.most_recent_entry,
    ((paramq.dataset_storage_path)::text || (j.dataset)::text) AS dataset_folder_path
   FROM (((((sw.t_step_tool_versions stv
     RIGHT JOIN (sw.t_job_steps_history js
     JOIN sw.t_job_step_state_name ssn ON ((js.state = ssn.step_state_id))) ON ((stv.tool_version_id = js.tool_version_id)))
     LEFT JOIN (sw.t_scripts s
     JOIN sw.t_jobs_history j ON ((s.script OPERATOR(public.=) j.script))) ON (((js.job = j.job) AND (js.saved = j.saved))))
     LEFT JOIN sw.t_remote_info ri ON ((js.remote_info_id = ri.remote_info_id)))
     LEFT JOIN sw.t_local_processors lp ON ((js.processor OPERATOR(public.=) lp.processor_name)))
     LEFT JOIN ( SELECT src.job,
            ((xpath('//params/Param[@Name = "SettingsFileName"]/@Value'::text, src.rooted_xml))[1])::public.citext AS settings_file,
            ((xpath('//params/Param[@Name = "ParamFileName"]/@Value'::text, src.rooted_xml))[1])::public.citext AS parameter_file,
            ((xpath('//params/Param[@Name = "DatasetStoragePath"]/@Value'::text, src.rooted_xml))[1])::public.citext AS dataset_storage_path
           FROM ( SELECT t_job_parameters_history.job,
                    ((('<params>'::text || (t_job_parameters_history.parameters)::text) || '</params>'::text))::xml AS rooted_xml
                   FROM sw.t_job_parameters_history
                  WHERE (t_job_parameters_history.most_recent_entry = 1)) src) paramq ON ((paramq.job = js.job)))
  WHERE (j.most_recent_entry = 1);


ALTER VIEW sw.v_job_steps_history2 OWNER TO d3l243;

--
-- Name: TABLE v_job_steps_history2; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_steps_history2 TO readaccess;
GRANT SELECT ON TABLE sw.v_job_steps_history2 TO writeaccess;

