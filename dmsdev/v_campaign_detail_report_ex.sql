--
-- Name: v_campaign_detail_report_ex; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_campaign_detail_report_ex AS
 SELECT c.campaign,
    c.project,
    c.state,
    drr.release_restriction AS data_release_restriction,
    c.description,
    c.comment,
    public.get_research_team_membership_list(c.research_team) AS team_members,
    rt.collaborators,
    c.external_links,
    c.epr_list,
    c.eus_proposal_list AS eus_proposal,
    c.fraction_emsl_funded,
    eut.eus_usage_type,
    c.organisms,
    c.experiment_prefixes,
    c.campaign_id AS id,
    c.created,
    ct.most_recent_activity,
    ct.biomaterial_count AS biomaterial,
    ct.biomaterial_most_recent AS most_recent_biomaterial,
    ct.sample_submission_count AS samples_submitted,
    ct.sample_submission_most_recent AS most_recent_sample_submission,
    ct.sample_prep_request_count AS sample_prep_requests,
    ct.sample_prep_request_most_recent AS most_recent_sample_prep_request,
    ct.experiment_count AS experiments,
    ct.experiment_most_recent AS most_recent_experiment,
    ct.run_request_count AS run_requests,
    ct.run_request_most_recent AS most_recent_run_request,
    ct.dataset_count AS datasets,
    ct.dataset_most_recent AS most_recent_dataset,
    ct.job_count AS analysis_jobs,
    ct.job_most_recent AS most_recent_analysis_job,
    ct.data_package_count AS data_packages,
    public.get_campaign_work_package_list((c.campaign)::text) AS work_packages
   FROM ((((public.t_campaign c
     JOIN public.t_data_release_restrictions drr ON ((c.data_release_restriction_id = drr.release_restriction_id)))
     JOIN public.t_eus_usage_type eut ON ((c.eus_usage_type_id = eut.eus_usage_type_id)))
     LEFT JOIN public.t_research_team rt ON ((c.research_team = rt.team_id)))
     LEFT JOIN public.t_campaign_tracking ct ON ((ct.campaign_id = c.campaign_id)));


ALTER VIEW public.v_campaign_detail_report_ex OWNER TO d3l243;

--
-- Name: TABLE v_campaign_detail_report_ex; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_campaign_detail_report_ex TO readaccess;
GRANT SELECT ON TABLE public.v_campaign_detail_report_ex TO writeaccess;

