--
-- Name: v_job_step_processing_stats_daily; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_step_processing_stats_daily AS
 SELECT theyear AS year,
    themonth AS month,
    theday AS day,
    (((((theyear)::text || '-'::text) || (themonth)::text) || '-'::text) || (theday)::text) AS date,
    sum(job_steps_run) AS job_steps_run
   FROM ( SELECT EXTRACT(year FROM t_job_step_processing_log.entered) AS theyear,
            EXTRACT(month FROM t_job_step_processing_log.entered) AS themonth,
            EXTRACT(day FROM t_job_step_processing_log.entered) AS theday,
            count(t_job_step_processing_log.event_id) AS job_steps_run
           FROM sw.t_job_step_processing_log
          GROUP BY (EXTRACT(year FROM t_job_step_processing_log.entered)), (EXTRACT(month FROM t_job_step_processing_log.entered)), (EXTRACT(day FROM t_job_step_processing_log.entered))
        UNION
         SELECT EXTRACT(year FROM t_job_step_processing_log.entered) AS theyear,
            EXTRACT(month FROM t_job_step_processing_log.entered) AS themonth,
            EXTRACT(day FROM t_job_step_processing_log.entered) AS theday,
            count(t_job_step_processing_log.event_id) AS job_steps_run
           FROM logsw.t_job_step_processing_log
          GROUP BY (EXTRACT(year FROM t_job_step_processing_log.entered)), (EXTRACT(month FROM t_job_step_processing_log.entered)), (EXTRACT(day FROM t_job_step_processing_log.entered))) sourceq
  GROUP BY theyear, themonth, theday;


ALTER VIEW sw.v_job_step_processing_stats_daily OWNER TO d3l243;

--
-- Name: TABLE v_job_step_processing_stats_daily; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_step_processing_stats_daily TO readaccess;
GRANT SELECT ON TABLE sw.v_job_step_processing_stats_daily TO writeaccess;

