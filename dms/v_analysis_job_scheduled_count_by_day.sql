--
-- Name: v_analysis_job_scheduled_count_by_day; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_scheduled_count_by_day AS
 SELECT (t_analysis_job.created)::date AS date,
    count(*) AS number_of_analysis_jobs_scheduled
   FROM public.t_analysis_job
  WHERE (t_analysis_job.job_state_id = 4)
  GROUP BY ((t_analysis_job.created)::date);


ALTER TABLE public.v_analysis_job_scheduled_count_by_day OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_scheduled_count_by_day; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_scheduled_count_by_day TO readaccess;
