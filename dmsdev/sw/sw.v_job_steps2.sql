--
-- Name: v_job_steps2; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_steps2 AS
 SELECT dataq.job,
    dataq.dataset,
    dataq.step,
    dataq.script,
    dataq.tool,
    paramq.settings_file,
    paramq.parameter_file,
    dataq.state_name,
    dataq.state,
    dataq.start,
    dataq.finish,
    dataq.runtime_minutes,
    dataq.last_cpu_status_minutes,
    dataq.job_progress,
    dataq.runtime_predicted_hours,
    dataq.processor,
    dataq.process_id,
    dataq.prog_runner_process_id,
    dataq.prog_runner_core_usage,
        CASE
            WHEN (NOT dataq.processorwarningflag) THEN ((('pskill \\'::text || (dataq.machine)::text) || ' '::text) || (dataq.process_id)::text)
            ELSE 'Processor Warning'::text
        END AS kill_manager,
        CASE
            WHEN (NOT dataq.processorwarningflag) THEN ((('pskill \\'::text || (dataq.machine)::text) || ' '::text) || (dataq.prog_runner_process_id)::text)
            ELSE 'Processor Warning'::text
        END AS kill_prog_runner,
    dataq.processor_warning,
    dataq.input_folder,
    dataq.output_folder,
    dataq.priority,
    dataq.signature,
    dataq.dependencies,
    dataq.cpu_load,
    dataq.actual_cpu_load,
    dataq.memory_usage_mb,
    dataq.tool_version_id,
    dataq.tool_version,
    dataq.completion_code,
    dataq.completion_message,
    dataq.evaluation_code,
    dataq.evaluation_message,
    dataq.next_try,
    dataq.retry_count,
    dataq.remote_info_id,
    dataq.remote_info,
    dataq.remote_timestamp,
    dataq.remote_start,
    dataq.remote_finish,
    dataq.remote_progress,
    dataq.dataset_id,
    dataq.data_pkg_id,
    dataq.machine,
    dataq.workdirpath AS work_dir_path,
    dataq.transfer_folder_path,
    ((paramq.dataset_storage_path)::text || (dataq.dataset)::text) AS dataset_folder_path,
    ((((((((dataq.log_file_path ||
        CASE
            WHEN (EXTRACT(year FROM CURRENT_TIMESTAMP) <> EXTRACT(year FROM dataq.start)) THEN (dataq.theyear || '\'::text)
            ELSE ''::text
        END) || 'AnalysisMgr_'::text) || dataq.theyear) || '-'::text) || dataq.themonth) || '-'::text) || dataq.theday) || '.txt'::text) AS log_file_path
   FROM (( SELECT js.job,
            js.dataset,
            js.step,
            js.script,
            js.tool,
            js.state_name,
            js.state,
            js.start,
            js.finish,
            js.runtime_minutes,
            js.last_cpu_status_minutes,
            js.job_progress,
            js.runtime_predicted_hours,
            js.processor,
            js.process_id,
            js.prog_runner_process_id,
            js.prog_runner_core_usage,
            js.processor_warning,
                CASE
                    WHEN (COALESCE(js.processor_warning, ''::text) = ''::text) THEN false
                    ELSE true
                END AS processorwarningflag,
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
            lp.machine,
            lp.work_dir_admin_share AS workdirpath,
            js.transfer_folder_path,
            js.log_file_path,
            (EXTRACT(year FROM js.start))::text AS theyear,
            to_char(EXTRACT(month FROM js.start), 'fm00'::text) AS themonth,
            to_char(EXTRACT(day FROM js.start), 'fm00'::text) AS theday
           FROM (sw.v_job_steps js
             LEFT JOIN sw.t_local_processors lp ON ((js.processor OPERATOR(public.=) lp.processor_name)))) dataq
     LEFT JOIN ( SELECT src.job,
            ((xpath('//params/Param[@Name = "SettingsFileName"]/@Value'::text, src.rooted_xml))[1])::public.citext AS settings_file,
            ((xpath('//params/Param[@Name = "ParamFileName"]/@Value'::text, src.rooted_xml))[1])::public.citext AS parameter_file,
            ((xpath('//params/Param[@Name = "DatasetStoragePath"]/@Value'::text, src.rooted_xml))[1])::public.citext AS dataset_storage_path
           FROM ( SELECT t_job_parameters.job,
                    ((('<params>'::text || (t_job_parameters.parameters)::text) || '</params>'::text))::xml AS rooted_xml
                   FROM sw.t_job_parameters) src) paramq ON ((paramq.job = dataq.job)));


ALTER VIEW sw.v_job_steps2 OWNER TO d3l243;

--
-- Name: TABLE v_job_steps2; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_steps2 TO readaccess;
GRANT SELECT ON TABLE sw.v_job_steps2 TO writeaccess;

