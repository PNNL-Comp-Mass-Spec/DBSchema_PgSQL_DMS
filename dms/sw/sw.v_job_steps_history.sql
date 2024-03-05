--
-- Name: v_job_steps_history; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_steps_history AS
 SELECT jobq.job,
    jobq.dataset,
    js.step,
    jobq.script,
    js.tool,
    ssn.step_state AS state_name,
    js.state,
    js.start,
    js.finish,
        CASE
            WHEN ((js.remote_info_id > 1) AND (NOT (js.remote_start IS NULL))) THEN round((EXTRACT(epoch FROM (COALESCE((js.remote_finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.remote_start)::timestamp with time zone)) / (60)::numeric), 1)
            WHEN (NOT (js.finish IS NULL)) THEN round((EXTRACT(epoch FROM (COALESCE((js.finish)::timestamp with time zone, CURRENT_TIMESTAMP) - (js.start)::timestamp with time zone)) / (60)::numeric), 1)
            ELSE NULL::numeric
        END AS runtime_minutes,
    js.processor,
    js.input_folder_name AS input_folder,
    js.output_folder_name AS output_folder,
    jobq.priority,
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
    jobq.dataset_id,
    js.saved,
    js.most_recent_entry
   FROM ((((( SELECT j.job,
            j.dataset,
            s.script,
            j.priority,
            j.dataset_id,
            j.saved
           FROM (sw.t_jobs_history j
             LEFT JOIN sw.t_scripts s ON ((s.script OPERATOR(public.=) j.script)))
          WHERE (j.most_recent_entry = 1)) jobq
     JOIN sw.t_job_steps_history js ON (((js.job = jobq.job) AND (js.saved = jobq.saved))))
     JOIN sw.t_job_step_state_name ssn ON ((js.state = ssn.step_state_id)))
     LEFT JOIN sw.t_step_tool_versions stv ON ((stv.tool_version_id = js.tool_version_id)))
     LEFT JOIN sw.t_remote_info ri ON ((js.remote_info_id = ri.remote_info_id)));


ALTER VIEW sw.v_job_steps_history OWNER TO d3l243;

--
-- Name: TABLE v_job_steps_history; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_steps_history TO readaccess;
GRANT SELECT ON TABLE sw.v_job_steps_history TO writeaccess;

