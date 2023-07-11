--
-- Name: v_statistics_analysis_jobs_by_day; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_statistics_analysis_jobs_by_day AS
 SELECT EXTRACT(year FROM aj.start) AS year,
    EXTRACT(month FROM aj.start) AS month,
    EXTRACT(day FROM aj.start) AS day,
    (aj.start)::date AS date,
    count(aj.job) AS jobs_run
   FROM (public.t_analysis_job aj
     JOIN public.t_analysis_tool tool ON ((aj.analysis_tool_id = tool.analysis_tool_id)))
  WHERE ((NOT (aj.start IS NULL)) AND (tool.analysis_tool OPERATOR(public.<>) 'MSClusterDAT_Gen'::public.citext))
  GROUP BY (EXTRACT(year FROM aj.start)), (EXTRACT(month FROM aj.start)), (EXTRACT(day FROM aj.start)), ((aj.start)::date);


ALTER TABLE public.v_statistics_analysis_jobs_by_day OWNER TO d3l243;

--
-- Name: TABLE v_statistics_analysis_jobs_by_day; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_statistics_analysis_jobs_by_day TO readaccess;
GRANT SELECT ON TABLE public.v_statistics_analysis_jobs_by_day TO writeaccess;

