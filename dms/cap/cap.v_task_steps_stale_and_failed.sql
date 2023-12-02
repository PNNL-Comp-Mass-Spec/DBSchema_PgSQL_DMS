--
-- Name: v_task_steps_stale_and_failed; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_task_steps_stale_and_failed AS
 SELECT dataq.warning_message,
    dataq.dataset,
    dataq.dataset_id,
    dataq.job,
    dataq.script,
    dataq.tool,
    (dataq.runtime_minutes)::integer AS runtime_minutes,
    round((dataq.job_progress)::numeric, 1) AS job_progress,
    dataq.runtime_predicted_hours,
    (dataq.state_name)::public.citext AS state_name,
    round(((dataq.last_cpu_status_minutes)::numeric / 60.0), 1) AS last_cpu_status_hours,
    dataq.processor,
    dataq.start,
    dataq.step,
    dataq.completion_message,
    dataq.evaluation_message
   FROM ( SELECT
                CASE
                    WHEN ((ts.state = 4) AND ((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (ts.start)::timestamp with time zone)) / 3600.0) >= (5)::numeric)) THEN 'Job step running over 5 hours'::text
                    WHEN ((ts.state = 6) AND (ts.start >= (CURRENT_TIMESTAMP - '14 days'::interval)) AND (ts.job_state <> 101)) THEN 'Job step failed within the last 14 days'::text
                    WHEN (NOT (failedjobq.job IS NULL)) THEN 'Overall job state is "failed"'::text
                    ELSE ''::text
                END AS warning_message,
            ts.job,
            ts.dataset,
            ts.dataset_id,
            ts.step,
            ts.script,
            ts.tool,
            ts.state,
                CASE
                    WHEN (ts.state = 4) THEN 'Stale'::text
                    ELSE
                    CASE
                        WHEN ((failedjobq.job IS NULL) OR (ts.state = 6)) THEN (ts.state_name)::text
                        ELSE ((ts.state_name)::text || ' (Failed in cap.t_tasks)'::text)
                    END
                END AS state_name,
            ts.start,
            ts.runtime_minutes,
            ts.last_cpu_status_minutes,
            ts.job_progress,
            ts.runtime_predicted_hours,
            ts.processor,
            ts.priority,
            COALESCE(ts.completion_message, ''::public.citext) AS completion_message,
            COALESCE(ts.evaluation_message, ''::public.citext) AS evaluation_message
           FROM ((cap.v_task_steps ts
             LEFT JOIN ( SELECT lookupq.job,
                    lookupq.step
                   FROM ( SELECT js_1.job,
                            js_1.step,
                            js_1.state AS stepstate,
                            row_number() OVER (PARTITION BY t.job ORDER BY js_1.state DESC) AS rowrank
                           FROM (cap.t_tasks t
                             JOIN cap.t_task_steps js_1 ON ((t.job = js_1.job)))
                          WHERE ((t.state = 5) AND (t.start >= (CURRENT_TIMESTAMP - '14 days'::interval)))) lookupq
                  WHERE (lookupq.rowrank = 1)) failedjobq ON (((ts.job = failedjobq.job) AND (ts.step = failedjobq.step))))
             LEFT JOIN cap.t_local_processors lp ON ((ts.processor OPERATOR(public.=) lp.processor_name)))) dataq
  WHERE (dataq.warning_message <> ''::text);


ALTER VIEW cap.v_task_steps_stale_and_failed OWNER TO d3l243;

--
-- Name: TABLE v_task_steps_stale_and_failed; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_task_steps_stale_and_failed TO readaccess;
GRANT SELECT ON TABLE cap.v_task_steps_stale_and_failed TO writeaccess;

