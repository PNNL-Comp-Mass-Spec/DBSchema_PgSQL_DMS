--
-- Name: v_job_processing_time; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_processing_time AS
 SELECT steptoolq.job,
    (sum(steptoolq.maxsecondselapsedbytool) / 60.0) AS processing_time_minutes,
    (sum(steptoolq.maxsecondselapsedbytool_completedsteps) / 60.0) AS proc_time_minutes_completed_steps
   FROM ( SELECT statsq.job,
            statsq.step_tool,
            max((COALESCE(statsq.secondselapsedcomplete, (0)::numeric) + COALESCE(statsq.secondselapsedinprogress, (0)::numeric))) AS maxsecondselapsedbytool,
            max(COALESCE(statsq.secondselapsedcomplete, (0)::numeric)) AS maxsecondselapsedbytool_completedsteps
           FROM ( SELECT t_job_steps.job,
                    t_job_steps.step_tool,
                        CASE
                            WHEN (((t_job_steps.state = 9) OR (t_job_steps.retry_count > 0)) AND (NOT (t_job_steps.remote_start IS NULL))) THEN
                            CASE
                                WHEN ((NOT (t_job_steps.remote_start IS NULL)) AND (t_job_steps.remote_finish > t_job_steps.remote_start)) THEN EXTRACT(epoch FROM (t_job_steps.remote_finish - t_job_steps.remote_start))
                                ELSE NULL::numeric
                            END
                            ELSE
                            CASE
                                WHEN ((NOT (t_job_steps.start IS NULL)) AND (t_job_steps.finish > t_job_steps.start)) THEN EXTRACT(epoch FROM (t_job_steps.finish - t_job_steps.start))
                                ELSE NULL::numeric
                            END
                        END AS secondselapsedcomplete,
                        CASE
                            WHEN (((t_job_steps.state = 9) OR (t_job_steps.retry_count > 0)) AND (NOT (t_job_steps.remote_start IS NULL))) THEN
                            CASE
                                WHEN (t_job_steps.remote_finish IS NULL) THEN EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (t_job_steps.remote_start)::timestamp with time zone))
                                ELSE NULL::numeric
                            END
                            ELSE
                            CASE
                                WHEN ((NOT (t_job_steps.start IS NULL)) AND (t_job_steps.finish IS NULL)) THEN EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (t_job_steps.start)::timestamp with time zone))
                                ELSE NULL::numeric
                            END
                        END AS secondselapsedinprogress
                   FROM sw.t_job_steps) statsq
          GROUP BY statsq.job, statsq.step_tool) steptoolq
  GROUP BY steptoolq.job;


ALTER TABLE sw.v_job_processing_time OWNER TO d3l243;

--
-- Name: TABLE v_job_processing_time; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_processing_time TO readaccess;
GRANT SELECT ON TABLE sw.v_job_processing_time TO writeaccess;

