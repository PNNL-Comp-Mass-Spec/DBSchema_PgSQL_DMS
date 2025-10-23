--
-- Name: v_job_step_processing_stats3; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_step_processing_stats3 AS
 SELECT dataq.entered,
    dataq.job,
    dataq.dataset,
    dataq.step,
    dataq.script,
    dataq.tool,
    dataq.start,
    dataq.finish,
    dataq.runtime_minutes_snapshot,
    dataq.current_runtime_minutes,
    dataq.job_progress_snapshot,
    dataq.current_progress,
    dataq.runtime_predicted_hours_snapshot,
    dataq.current_runtime_predicted_hours,
    dataq.processor,
    dataq.prog_runner_core_usage,
    dataq.cpu_load,
    dataq.actual_cpu_load,
    dataq.current_state_name,
    dataq.current_state,
    dataq.transfer_folder_path,
    ((((((((dataq.logfolderpath ||
        CASE
            WHEN (EXTRACT(year FROM CURRENT_TIMESTAMP) <> EXTRACT(year FROM dataq.start)) THEN (dataq.theyear || '\'::text)
            ELSE ''::text
        END) || 'AnalysisMgr_'::text) || dataq.theyear) || '-'::text) || dataq.themonth) || '-'::text) || dataq.theday) || '.txt'::text) AS log_file_path
   FROM (( SELECT jsps.entered,
            jsps.job,
            j.dataset,
            jsps.step,
            j.script,
            js.tool,
            js.start,
            js.finish,
            jsps.runtime_minutes AS runtime_minutes_snapshot,
            js.runtime_minutes AS current_runtime_minutes,
            jsps.job_progress AS job_progress_snapshot,
            js.job_progress AS current_progress,
            jsps.runtime_predicted_hours AS runtime_predicted_hours_snapshot,
            js.runtime_predicted_hours AS current_runtime_predicted_hours,
            jsps.processor,
            jsps.prog_runner_core_usage,
            jsps.cpu_load,
            jsps.actual_cpu_load,
            ssn.step_state AS current_state_name,
            js.state AS current_state,
            js.transfer_folder_path,
            ((((('\\'::text || (lp.machine)::text) ||
                CASE
                    WHEN m.bionet_only THEN '.bionet'::text
                    ELSE ''::text
                END) || '\DMS_Programs\AnalysisToolManager'::text) ||
                CASE
                    WHEN (js.processor OPERATOR(public.~) similar_to_escape('%-[1-9]'::text)) THEN "right"((js.processor)::text, 1)
                    ELSE ''::text
                END) || '\Logs\'::text) AS logfolderpath,
            (EXTRACT(year FROM js.start))::text AS theyear,
            to_char(EXTRACT(month FROM js.start), 'fm00'::text) AS themonth,
            to_char(EXTRACT(day FROM js.start), 'fm00'::text) AS theday
           FROM (((sw.t_job_step_processing_stats jsps
             LEFT JOIN sw.t_local_processors lp ON ((lp.processor_name OPERATOR(public.=) jsps.processor)))
             LEFT JOIN sw.t_machines m ON ((lp.machine OPERATOR(public.=) m.machine)))
             LEFT JOIN ((sw.t_jobs j
             JOIN sw.v_job_steps js ON ((j.job = js.job)))
             JOIN sw.t_job_step_state_name ssn ON ((js.state = ssn.step_state_id))) ON (((jsps.job = js.job) AND (jsps.step = js.step))))) dataq
     JOIN ( SELECT t_job_step_processing_stats.job,
            t_job_step_processing_stats.step,
            count(t_job_step_processing_stats.entry_id) AS entries
           FROM sw.t_job_step_processing_stats
          WHERE (t_job_step_processing_stats.entered >= (CURRENT_TIMESTAMP - '5 days'::interval))
          GROUP BY t_job_step_processing_stats.job, t_job_step_processing_stats.step
         HAVING (count(*) > 25)) filterq ON (((dataq.job = filterq.job) AND (dataq.step = filterq.step))));


ALTER VIEW sw.v_job_step_processing_stats3 OWNER TO d3l243;

--
-- Name: TABLE v_job_step_processing_stats3; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_step_processing_stats3 TO readaccess;
GRANT SELECT ON TABLE sw.v_job_step_processing_stats3 TO writeaccess;

