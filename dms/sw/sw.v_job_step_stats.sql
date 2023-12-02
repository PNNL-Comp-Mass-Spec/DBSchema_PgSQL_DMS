--
-- Name: v_job_step_stats; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_step_stats AS
 SELECT j.dataset,
    j.script,
    steptoolq.job,
    sum(steptoolq.jobsteps) AS job_steps,
    (sum(steptoolq.secondselapsedmax) / 60.0) AS processing_time_minutes,
    (sum(steptoolq.secondselapsedtotal) / 60.0) AS machine_time_minutes,
    j.start,
    j.finish,
    j.state AS job_state,
    jsn.job_state AS state_name,
    sum(steptoolq.stepcount_pending) AS step_count_pending,
    sum(steptoolq.stepcount_running) AS step_count_running,
    sum(steptoolq.stepcount_completed) AS step_count_completed,
    sum(steptoolq.stepcount_failed) AS step_count_failed
   FROM ((( SELECT statsq.job,
            statsq.step_tool,
            max((COALESCE(statsq.secondselapsed1, (0)::numeric) + COALESCE(statsq.secondselapsed2, (0)::numeric))) AS secondselapsedmax,
            sum((COALESCE(statsq.secondselapsed1, (0)::numeric) + COALESCE(statsq.secondselapsed2, (0)::numeric))) AS secondselapsedtotal,
            count(statsq.state) AS jobsteps,
            sum(
                CASE
                    WHEN (statsq.state = ANY (ARRAY[3, 5])) THEN 1
                    ELSE 0
                END) AS stepcount_completed,
            sum(
                CASE
                    WHEN (statsq.state = 4) THEN 1
                    ELSE 0
                END) AS stepcount_running,
            sum(
                CASE
                    WHEN (statsq.state = 6) THEN 1
                    ELSE 0
                END) AS stepcount_failed,
            sum(
                CASE
                    WHEN (statsq.state = ANY (ARRAY[1, 2, 7])) THEN 1
                    ELSE 0
                END) AS stepcount_pending
           FROM ( SELECT js.job,
                    js.tool AS step_tool,
                    js.state,
                    EXTRACT(epoch FROM (js.finish - js.start)) AS secondselapsed1,
                        CASE
                            WHEN ((NOT (js.start IS NULL)) AND (js.finish IS NULL)) THEN EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (js.start)::timestamp with time zone))
                            ELSE NULL::numeric
                        END AS secondselapsed2
                   FROM sw.t_job_steps js) statsq
          GROUP BY statsq.job, statsq.step_tool) steptoolq
     JOIN sw.t_jobs j ON ((steptoolq.job = j.job)))
     JOIN sw.t_job_state_name jsn ON ((j.state = jsn.job_state_id)))
  GROUP BY steptoolq.job, j.script, j.dataset, j.start, j.finish, j.state, jsn.job_state;


ALTER VIEW sw.v_job_step_stats OWNER TO d3l243;

--
-- Name: TABLE v_job_step_stats; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_step_stats TO readaccess;
GRANT SELECT ON TABLE sw.v_job_step_stats TO writeaccess;

