--
-- Name: v_analysis_job_completed_count_by_day; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_completed_count_by_day AS
 SELECT (finish)::date AS date,
    count(job) AS number_of_analysis_jobs_completed
   FROM public.t_analysis_job j
  WHERE (job_state_id = 4)
  GROUP BY ((finish)::date);


ALTER VIEW public.v_analysis_job_completed_count_by_day OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_completed_count_by_day; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_completed_count_by_day TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_completed_count_by_day TO writeaccess;

