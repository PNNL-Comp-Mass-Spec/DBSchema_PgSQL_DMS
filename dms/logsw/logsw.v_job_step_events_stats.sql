--
-- Name: v_job_step_events_stats; Type: VIEW; Schema: logsw; Owner: d3l243
--

CREATE VIEW logsw.v_job_step_events_stats AS
 SELECT EXTRACT(year FROM entered) AS the_year,
    EXTRACT(month FROM entered) AS the_month,
    min(EXTRACT(day FROM entered)) AS first_day_of_month,
    max(EXTRACT(day FROM entered)) AS last_day_of_month,
    count(*) AS job_steps,
    min(job) AS job_min,
    max(job) AS job_max
   FROM logsw.t_job_step_events
  GROUP BY (EXTRACT(year FROM entered)), (EXTRACT(month FROM entered));


ALTER VIEW logsw.v_job_step_events_stats OWNER TO d3l243;

