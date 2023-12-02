--
-- Name: v_job_steps_export; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_steps_export AS
 SELECT js.job,
    j.dataset,
    j.dataset_id,
    js.step,
    j.script,
    js.tool,
    ssn.step_state AS state_name,
    js.state,
    js.start,
    js.finish,
    js.processor,
    js.input_folder_name AS input_folder,
    js.output_folder_name AS output_folder,
    j.priority,
    js.signature,
    js.dependencies,
    js.cpu_load,
    js.actual_cpu_load,
    js.memory_usage_mb,
    js.completion_code,
    js.completion_message,
    js.evaluation_code,
    js.evaluation_message,
    js.next_try,
    js.retry_count,
    js.remote_info_id,
    js.remote_timestamp,
    js.remote_start,
    js.remote_finish,
    js.remote_progress,
    j.transfer_folder_path,
    js.tool_version_id,
    stv.tool_version
   FROM (((sw.t_job_steps js
     JOIN sw.t_job_step_state_name ssn ON ((js.state = ssn.step_state_id)))
     JOIN sw.t_jobs j ON ((js.job = j.job)))
     LEFT JOIN sw.t_step_tool_versions stv ON ((js.tool_version_id = stv.tool_version_id)));


ALTER VIEW sw.v_job_steps_export OWNER TO d3l243;

--
-- Name: TABLE v_job_steps_export; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_steps_export TO readaccess;
GRANT SELECT ON TABLE sw.v_job_steps_export TO writeaccess;

