--
-- Name: v_project_usage_stats2; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_project_usage_stats2 AS
 SELECT v_project_usage_stats.entry_id,
    v_project_usage_stats.start_date,
    v_project_usage_stats.end_date,
    v_project_usage_stats.year,
    v_project_usage_stats.week,
    v_project_usage_stats.proposal_id,
    v_project_usage_stats.work_package,
    v_project_usage_stats.proposal_active,
    v_project_usage_stats.project_type,
    v_project_usage_stats.samples,
    v_project_usage_stats.datasets,
    v_project_usage_stats.jobs,
    v_project_usage_stats.usage_type,
    v_project_usage_stats.proposal_user,
    v_project_usage_stats.proposal_title,
    v_project_usage_stats.instrument_first,
    v_project_usage_stats.instrument_last,
    v_project_usage_stats.job_tool_first,
    v_project_usage_stats.job_tool_last,
    v_project_usage_stats.proposal_start_date,
    v_project_usage_stats.proposal_end_date,
    v_project_usage_stats.proposal_type,
    v_project_usage_stats.sort_key
   FROM public.v_project_usage_stats
  WHERE (((v_project_usage_stats.year)::numeric = EXTRACT(year FROM CURRENT_TIMESTAMP)) AND ((v_project_usage_stats.week)::numeric >= (EXTRACT(week FROM CURRENT_TIMESTAMP) - (1)::numeric)) AND (NOT ((v_project_usage_stats.usage_type OPERATOR(public.=) ANY (ARRAY['CAP_DEV'::public.citext, 'Maintenance'::public.citext])) AND (v_project_usage_stats.project_type OPERATOR(public.=) 'Unknown'::public.citext))));


ALTER TABLE public.v_project_usage_stats2 OWNER TO d3l243;

--
-- Name: VIEW v_project_usage_stats2; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_project_usage_stats2 IS 'Show project stats for this week and the previous week, filtering out Maintenance and Cap_Dev that are not associated with a user proposal';

--
-- Name: TABLE v_project_usage_stats2; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_project_usage_stats2 TO readaccess;
GRANT SELECT ON TABLE public.v_project_usage_stats2 TO writeaccess;

