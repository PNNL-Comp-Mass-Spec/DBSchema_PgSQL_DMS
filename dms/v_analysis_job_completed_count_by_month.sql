--
-- Name: v_analysis_job_completed_count_by_month; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_completed_count_by_month AS
 SELECT make_date((EXTRACT(year FROM finish))::integer, (EXTRACT(month FROM finish))::integer, 1) AS date,
    count(job) AS number_of_analysis_jobs_completed
   FROM public.t_analysis_job j
  WHERE (job_state_id = 4)
  GROUP BY (EXTRACT(year FROM finish)), (EXTRACT(month FROM finish));


ALTER VIEW public.v_analysis_job_completed_count_by_month OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_completed_count_by_month; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_completed_count_by_month TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_completed_count_by_month TO writeaccess;

