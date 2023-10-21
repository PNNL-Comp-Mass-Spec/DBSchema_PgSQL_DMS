--
-- Name: v_campaign_list_report_2; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_campaign_list_report_2 AS
 SELECT c.campaign_id AS id,
    c.campaign,
    c.state,
    (public.get_campaign_role_person(c.campaign_id, 'Technical Lead'::text))::public.citext AS technical_lead,
    (public.get_campaign_role_person(c.campaign_id, 'PI'::text))::public.citext AS pi,
    (public.get_campaign_role_person(c.campaign_id, 'Project Mgr'::text))::public.citext AS project_mgr,
    c.project,
    c.description,
    c.created,
    ct.most_recent_activity,
    c.organisms,
    c.experiment_prefixes,
    c.fraction_emsl_funded,
    c.eus_proposal_list AS eus_proposals,
    eut.eus_usage_type,
    ct.biomaterial_count AS biomaterial,
    ct.sample_prep_request_count AS sample_prep_requests,
    ct.experiment_count AS experiments,
    ct.run_request_count AS requested_runs,
    ct.dataset_count AS datasets,
    ct.job_count AS analysis_jobs,
    ct.data_package_count AS data_packages
   FROM ((public.t_campaign c
     JOIN public.t_eus_usage_type eut ON ((c.eus_usage_type_id = eut.eus_usage_type_id)))
     LEFT JOIN public.t_campaign_tracking ct ON ((c.campaign_id = ct.campaign_id)));


ALTER TABLE public.v_campaign_list_report_2 OWNER TO d3l243;

--
-- Name: TABLE v_campaign_list_report_2; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_campaign_list_report_2 TO readaccess;
GRANT SELECT ON TABLE public.v_campaign_list_report_2 TO writeaccess;

