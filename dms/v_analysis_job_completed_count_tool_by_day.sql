--
-- Name: v_analysis_job_completed_count_tool_by_day; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_completed_count_tool_by_day AS
 SELECT (j.finish)::date AS date,
    t.analysis_tool AS tool,
    count(*) AS number_of_analysis_jobs_completed
   FROM (public.t_analysis_job j
     JOIN public.t_analysis_tool t ON ((j.analysis_tool_id = t.analysis_tool_id)))
  WHERE (j.job_state_id = 4)
  GROUP BY ((j.finish)::date), t.analysis_tool;


ALTER TABLE public.v_analysis_job_completed_count_tool_by_day OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_completed_count_tool_by_day; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_completed_count_tool_by_day TO readaccess;

