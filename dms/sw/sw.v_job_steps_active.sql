--
-- Name: v_job_steps_active; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_steps_active AS
 SELECT dataq.job,
    dataq.step,
    dataq.script,
    dataq.tool,
    dataq.state_name AS step_state,
    dataq.job_state_name AS job_state,
    dataq.dataset,
    dataq.start,
    dataq.finish,
    dataq.runtime_minutes,
    dataq.processor,
    round(((dataq.last_cpu_status_minutes)::numeric / 60.0), 1) AS last_cpu_status_hours,
    dataq.job_progress,
    dataq.runtime_predicted_hours,
    dataq.priority,
    dataq.settings_file,
    dataq.parameter_file,
    dataq.state,
    row_number() OVER (ORDER BY
        CASE
            WHEN (dataq.state = 4) THEN '-2'::integer
            WHEN (dataq.state = 6) THEN '-1'::integer
            ELSE (dataq.state)::integer
        END, dataq.job DESC, dataq.step) AS sort_order
   FROM ( SELECT js.job,
            js.dataset,
            js.step,
            js.script,
            js.tool,
            js.state,
                CASE
                    WHEN ((failedjobq.job IS NULL) OR (js.state = 6)) THEN js.state_name
                    ELSE (((js.state_name)::text || (' (Failed in sw.t_jobs)'::public.citext)::text))::public.citext
                END AS state_name,
            aj.settings_file_name AS settings_file,
            aj.param_file_name AS parameter_file,
            js.start,
            js.finish,
            js.runtime_minutes,
            js.last_cpu_status_minutes,
            js.job_progress,
            js.runtime_predicted_hours,
            js.processor,
            js.priority,
            jsn.job_state AS job_state_name
           FROM (((((sw.v_job_steps js
             JOIN sw.t_jobs j ON ((js.job = j.job)))
             JOIN sw.t_job_state_name jsn ON ((j.state = jsn.job_state_id)))
             LEFT JOIN ( SELECT lookupq.job,
                    lookupq.step
                   FROM ( SELECT js_1.job,
                            js_1.step,
                            js_1.state AS stepstate,
                            row_number() OVER (PARTITION BY j_1.job ORDER BY js_1.state DESC) AS rowrank
                           FROM (sw.t_jobs j_1
                             JOIN sw.t_job_steps js_1 ON ((j_1.job = js_1.job)))
                          WHERE ((j_1.state = 5) AND (j_1.start >= (CURRENT_TIMESTAMP - '21 days'::interval)))) lookupq
                  WHERE (lookupq.rowrank = 1)) failedjobq ON (((js.job = failedjobq.job) AND (js.step = failedjobq.step))))
             LEFT JOIN sw.t_local_processors lp ON ((js.processor OPERATOR(public.=) lp.processor_name)))
             LEFT JOIN public.t_analysis_job aj ON ((js.job = aj.job)))
          WHERE (((js.state = 6) AND (js.start >= (CURRENT_TIMESTAMP - '21 days'::interval))) OR ((js.state = ANY (ARRAY[1, 2])) AND (j.imported >= (CURRENT_TIMESTAMP - '120 days'::interval))) OR (js.state <> ALL (ARRAY[1, 3, 5, 6])) OR (js.start >= (CURRENT_TIMESTAMP - '1 day'::interval)) OR (NOT (failedjobq.job IS NULL)))) dataq;


ALTER TABLE sw.v_job_steps_active OWNER TO d3l243;

--
-- Name: VIEW v_job_steps_active; Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON VIEW sw.v_job_steps_active IS 'Failed within the last 21 days. Enabled/Waiting (and job imported within the last 120 days). Not Waiting, Skipped, Completed, or Failed. Job started within the last day. Job failed in T_Jobs (within the last 21 days)';

--
-- Name: TABLE v_job_steps_active; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_steps_active TO readaccess;
GRANT SELECT ON TABLE sw.v_job_steps_active TO writeaccess;

