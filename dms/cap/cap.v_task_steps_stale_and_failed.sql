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
    dataq.state_name,
    round(((dataq.last_cpu_status_minutes)::numeric / 60.0), 1) AS last_cpu_status_hours,
    dataq.processor,
    dataq.start,
    dataq.step,
    dataq.completion_message,
    dataq.evaluation_message
   FROM ( SELECT
                CASE
                    WHEN ((js.state = 4) AND ((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (js.start)::timestamp with time zone)) / 3600.0) >= (5)::numeric)) THEN 'Job step running over 5 hours'::text
                    WHEN ((js.state = 6) AND (js.start >= (CURRENT_TIMESTAMP - '14 days'::interval)) AND (js.job_state <> 101)) THEN 'Job step failed within the last 14 days'::text
                    WHEN (NOT (failedjobq.job IS NULL)) THEN 'Overall job state is "failed"'::text
                    ELSE ''::text
                END AS warning_message,
            js.job,
            js.dataset,
            js.dataset_id,
            js.step,
            js.script,
            js.tool,
            js.state,
                CASE
                    WHEN (js.state = 4) THEN 'Stale'::text
                    ELSE
                    CASE
                        WHEN ((failedjobq.job IS NULL) OR (js.state = 6)) THEN (js.state_name)::text
                        ELSE ((js.state_name)::text || ' (Failed in cap.t_tasks)'::text)
                    END
                END AS state_name,
            js.start,
            js.runtime_minutes,
            js.last_cpu_status_minutes,
            js.job_progress,
            js.runtime_predicted_hours,
            js.processor,
            js.priority,
            COALESCE(js.completion_message, ''::public.citext) AS completion_message,
            COALESCE(js.evaluation_message, ''::public.citext) AS evaluation_message
           FROM ((cap.v_task_steps js
             LEFT JOIN ( SELECT lookupq.job,
                    lookupq.step
                   FROM ( SELECT js_1.job,
                            js_1.step,
                            js_1.state AS stepstate,
                            row_number() OVER (PARTITION BY j.job ORDER BY js_1.state DESC) AS rowrank
                           FROM (cap.t_tasks j
                             JOIN cap.t_task_steps js_1 ON ((j.job = js_1.job)))
                          WHERE ((j.state = 5) AND (j.start >= (CURRENT_TIMESTAMP - '14 days'::interval)))) lookupq
                  WHERE (lookupq.rowrank = 1)) failedjobq ON (((js.job = failedjobq.job) AND (js.step = failedjobq.step))))
             LEFT JOIN cap.t_local_processors lp ON ((js.processor OPERATOR(public.=) lp.processor_name)))) dataq
  WHERE (dataq.warning_message <> ''::text);


ALTER TABLE cap.v_task_steps_stale_and_failed OWNER TO d3l243;
