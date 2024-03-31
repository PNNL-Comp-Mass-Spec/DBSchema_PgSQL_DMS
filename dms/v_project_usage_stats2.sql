--
-- Name: v_project_usage_stats2; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_project_usage_stats2 AS
 SELECT entry_id,
    start_date,
    end_date,
    year,
    week,
    proposal_id,
    work_package,
    proposal_active,
    project_type,
    samples,
    datasets,
    jobs,
    usage_type,
    proposal_user,
    proposal_title,
    instrument_first,
    instrument_last,
    job_tool_first,
    job_tool_last,
    proposal_start_date,
    proposal_end_date,
    proposal_type,
    sort_key
   FROM public.v_project_usage_stats
  WHERE (((year)::numeric = EXTRACT(year FROM CURRENT_TIMESTAMP)) AND ((week)::numeric >= (EXTRACT(week FROM CURRENT_TIMESTAMP) - (1)::numeric)) AND (NOT ((usage_type OPERATOR(public.=) ANY (ARRAY['CAP_DEV'::public.citext, 'MAINTENANCE'::public.citext, 'RESOURCE_OWNER'::public.citext])) AND (project_type OPERATOR(public.=) 'Unknown'::public.citext))));


ALTER VIEW public.v_project_usage_stats2 OWNER TO d3l243;

--
-- Name: VIEW v_project_usage_stats2; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_project_usage_stats2 IS 'Show project stats for this week and the previous week, filtering out Maintenance and Cap_Dev that are not associated with a user proposal';

--
-- Name: TABLE v_project_usage_stats2; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_project_usage_stats2 TO readaccess;
GRANT SELECT ON TABLE public.v_project_usage_stats2 TO writeaccess;

