--
-- Name: v_project_usage_stats; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_project_usage_stats AS
 SELECT stats.entry_id,
    stats.start_date,
    stats.end_date,
    stats.the_year AS year,
    stats.week_of_year AS week,
    stats.proposal_id,
    stats.work_package,
    stats.proposal_active,
    projecttypes.project_type_name AS project_type,
    stats.samples,
    stats.datasets,
    stats.jobs,
    eususage.eus_usage_type AS usage_type,
    stats.proposal_user,
    proposals.title AS proposal_title,
    stats.instrument_first,
    stats.instrument_last,
    stats.job_tool_first,
    stats.job_tool_last,
    (proposals.proposal_start_date)::date AS proposal_start_date,
    (proposals.proposal_end_date)::date AS proposal_end_date,
    stats.proposal_type,
    stats.sort_key AS sortkey
   FROM (((public.t_project_usage_stats stats
     JOIN public.t_project_usage_types projecttypes ON ((stats.project_type_id = projecttypes.project_type_id)))
     JOIN public.t_eus_usage_type eususage ON ((stats.eus_usage_type_id = eususage.eus_usage_type_id)))
     LEFT JOIN public.t_eus_proposals proposals ON ((stats.proposal_id OPERATOR(public.=) proposals.proposal_id)));


ALTER TABLE public.v_project_usage_stats OWNER TO d3l243;

--
-- Name: TABLE v_project_usage_stats; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_project_usage_stats TO readaccess;
GRANT SELECT ON TABLE public.v_project_usage_stats TO writeaccess;

