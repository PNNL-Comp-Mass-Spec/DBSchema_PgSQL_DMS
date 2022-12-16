--
-- Name: v_job_steps_stale_and_failed; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_steps_stale_and_failed AS
 SELECT dataq.warning_message,
    dataq.job,
    dataq.tool,
    (round(dataq.runtime_minutes, 0))::integer AS runtime_minutes,
    round((dataq.job_progress)::numeric, 1) AS job_progress,
    dataq.runtime_predicted_hours,
    dataq.state_name,
    round(((dataq.last_cpu_status_minutes)::numeric / 60.0), 1) AS last_cpu_status_hours,
    dataq.processor,
    dataq.start,
    dataq.step,
    dataq.dataset,
    dataq.settings_file,
    dataq.parameter_file,
    dataq.completion_message,
    dataq.evaluation_message
   FROM ( SELECT
                CASE
                    WHEN ((js.state = 4) AND (js.last_cpu_status_minutes >= (4 * 60))) THEN 'No status update for 4 hours'::text
                    WHEN ((js.state = 4) AND (js.runtime_predicted_hours >= (36)::numeric)) THEN 'Job predicted to run over 36 hours'::text
                    WHEN ((js.state = 4) AND (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (js.start)::timestamp with time zone)) / (86400)::numeric), 0) >= (4)::numeric)) THEN 'Job step running over 4 days'::text
                    WHEN ((js.state = ANY (ARRAY[6, 16])) AND (js.start >= (CURRENT_TIMESTAMP - '14 days'::interval))) THEN 'Job step failed within the last 14 days'::text
                    WHEN ((js.tool OPERATOR(public.~~) '%sequest%'::public.citext) AND ((js.evaluation_code & 2) = 2) AND (js.start >= (CURRENT_TIMESTAMP - '2 days'::interval))) THEN 'SEQUEST node count is less than the expected value'::text
                    WHEN (NOT (failedjobq.job IS NULL)) THEN 'Overall job state is "failed"'::text
                    ELSE ''::text
                END AS warning_message,
            js.job,
            js.dataset,
            js.step,
            js.script,
            js.tool,
            js.state,
                CASE
                    WHEN (js.state = 4) THEN 'Stale'::text
                    ELSE
                    CASE
                        WHEN ((failedjobq.job IS NULL) OR (js.state = ANY (ARRAY[6, 16]))) THEN (js.state_name)::text
                        ELSE ((js.state_name)::text || ' (Failed in sw.t_jobs)'::text)
                    END
                END AS state_name,
            aj.settings_file_name AS settings_file,
            aj.param_file_name AS parameter_file,
            js.start,
            js.runtime_minutes,
            js.last_cpu_status_minutes,
            js.job_progress,
            js.runtime_predicted_hours,
            js.processor,
            js.priority,
            COALESCE(js.completion_message, ''::public.citext) AS completion_message,
            COALESCE(js.evaluation_message, ''::public.citext) AS evaluation_message
           FROM (((sw.v_job_steps js
             LEFT JOIN ( SELECT lookupq.job,
                    lookupq.step
                   FROM ( SELECT js_1.job,
                            js_1.step,
                            js_1.state AS stepstate,
                            row_number() OVER (PARTITION BY j.job ORDER BY js_1.state DESC) AS rowrank
                           FROM (sw.t_jobs j
                             JOIN sw.t_job_steps js_1 ON ((j.job = js_1.job)))
                          WHERE ((j.state = 5) AND (j.start >= (CURRENT_TIMESTAMP - '14 days'::interval)))) lookupq
                  WHERE (lookupq.rowrank = 1)) failedjobq ON (((js.job = failedjobq.job) AND (js.step = failedjobq.step))))
             LEFT JOIN sw.t_local_processors lp ON ((js.processor OPERATOR(public.=) lp.processor_name)))
             LEFT JOIN public.t_analysis_job aj ON ((js.job = aj.job)))) dataq
  WHERE (dataq.warning_message <> ''::text);


ALTER TABLE sw.v_job_steps_stale_and_failed OWNER TO d3l243;

--
-- Name: VIEW v_job_steps_stale_and_failed; Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON VIEW sw.v_job_steps_stale_and_failed IS 'Use a Bitwise Or to look for Evaluation_Codes that include Code 2, which indicates for Sequest that NodeCountActive is less than the expected value. Look for jobs that are failed and started within the last 14 days. The subquery is used to find the highest step state for each job';

--
-- Name: TABLE v_job_steps_stale_and_failed; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_steps_stale_and_failed TO readaccess;
GRANT SELECT ON TABLE sw.v_job_steps_stale_and_failed TO writeaccess;

