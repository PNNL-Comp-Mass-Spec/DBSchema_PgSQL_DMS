--
-- Name: v_job_step_processing_log; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_step_processing_log AS
 WITH rankq(job, step, jobstart, jslrank) AS (
         SELECT t_job_step_processing_log.job,
            t_job_step_processing_log.step,
            t_job_step_processing_log.entered AS job_start,
            row_number() OVER (PARTITION BY t_job_step_processing_log.job, t_job_step_processing_log.step ORDER BY t_job_step_processing_log.entered) AS jslrank
           FROM sw.t_job_step_processing_log
        )
 SELECT jspl.job,
    jspl.step,
    jspl.processor,
    jspl.entered,
    jse.entered AS entered_state,
    jse.target_state,
    (((((((((('\\'::text || (lp.machine)::text) || '\DMS_Programs\AnalysisToolManager'::text) || (lp.proc_tool_mgr_id)::text) || '\Logs\AnalysisMgr_'::text) || (EXTRACT(year FROM jspl.entered))::text) || '-'::text) || to_char(EXTRACT(month FROM jspl.entered), 'fm00'::text)) || '-'::text) || to_char(EXTRACT(day FROM jspl.entered), 'fm00'::text)) || '.txt'::text) AS logfilepath
   FROM ((((sw.t_job_step_processing_log jspl
     JOIN sw.t_job_step_events jse ON (((jspl.job = jse.job) AND (jspl.step = jse.step) AND (jse.entered >= (jspl.entered - '00:00:01'::interval)))))
     JOIN rankq thisjspl ON (((jspl.job = thisjspl.job) AND (jspl.step = thisjspl.step) AND (jspl.entered = thisjspl.jobstart))))
     LEFT JOIN rankq nextjspl ON (((jspl.job = nextjspl.job) AND (jspl.step = nextjspl.step) AND ((thisjspl.jslrank + 1) = nextjspl.jslrank))))
     JOIN sw.t_local_processors lp ON ((jspl.processor OPERATOR(public.=) lp.processor_name)))
  WHERE ((jse.entered < COALESCE((nextjspl.jobstart)::timestamp with time zone, CURRENT_TIMESTAMP)) AND (jse.target_state <> ALL (ARRAY[0, 1, 2])));


ALTER VIEW sw.v_job_step_processing_log OWNER TO d3l243;

--
-- Name: TABLE v_job_step_processing_log; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_step_processing_log TO readaccess;
GRANT SELECT ON TABLE sw.v_job_step_processing_log TO writeaccess;

