--
-- Name: v_task_step_processing_log; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_task_step_processing_log AS
 WITH rankq(job, step, jobstart, jslrank) AS (
         SELECT t_task_step_processing_log.job,
            t_task_step_processing_log.step,
            t_task_step_processing_log.entered AS job_start,
            row_number() OVER (PARTITION BY t_task_step_processing_log.job, t_task_step_processing_log.step ORDER BY t_task_step_processing_log.entered) AS jslrank
           FROM cap.t_task_step_processing_log
        )
 SELECT jspl.job,
    jspl.step,
    jspl.processor,
    jspl.entered,
    jse.entered AS entered_state,
    jse.target_state,
    (((((('\\'::text || (lp.machine)::text) || '\DMS_Programs\CaptureTaskManager'::text) ||
        CASE
            WHEN (jspl.processor OPERATOR(public.~) similar_to_escape('%[-_][1-9]'::text)) THEN "right"((jspl.processor)::text, 2)
            ELSE ''::text
        END) || '\Logs\CapTaskMan_'::text) || to_char(jspl.entered, 'yyyy-mm-dd'::text)) || '.txt'::text) AS logfilepath
   FROM ((((cap.t_task_step_processing_log jspl
     JOIN cap.t_task_step_events jse ON (((jspl.job = jse.job) AND (jspl.step = jse.step) AND (jse.entered >= (jspl.entered - '00:00:01'::interval)))))
     JOIN rankq thisjspl ON (((jspl.job = thisjspl.job) AND (jspl.step = thisjspl.step) AND (jspl.entered = thisjspl.jobstart))))
     LEFT JOIN rankq nextjspl ON (((jspl.job = nextjspl.job) AND (jspl.step = nextjspl.step) AND ((thisjspl.jslrank + 1) = nextjspl.jslrank))))
     JOIN cap.t_local_processors lp ON ((jspl.processor OPERATOR(public.=) lp.processor_name)))
  WHERE ((jse.entered < COALESCE((nextjspl.jobstart)::timestamp with time zone, CURRENT_TIMESTAMP)) AND (jse.target_state <> ALL (ARRAY[0, 1, 2])));


ALTER TABLE cap.v_task_step_processing_log OWNER TO d3l243;

--
-- Name: TABLE v_task_step_processing_log; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_task_step_processing_log TO readaccess;
GRANT SELECT ON TABLE cap.v_task_step_processing_log TO writeaccess;

