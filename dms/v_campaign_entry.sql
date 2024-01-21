--
-- Name: v_campaign_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_campaign_entry AS
 SELECT c.campaign,
    c.project,
    public.get_campaign_role_person_list(c.campaign_id, 'PI'::text, 'USERNAME'::text) AS pi_username,
    public.get_campaign_role_person_list(c.campaign_id, 'Project Mgr'::text, 'USERNAME'::text) AS project_mgr,
    public.get_campaign_role_person_list(c.campaign_id, 'Technical Lead'::text, 'USERNAME'::text) AS technical_lead,
    public.get_campaign_role_person_list(c.campaign_id, 'Sample Preparation'::text, 'USERNAME'::text) AS sample_preparation_staff,
    public.get_campaign_role_person_list(c.campaign_id, 'Dataset Acquisition'::text, 'USERNAME'::text) AS dataset_acquisition_staff,
    public.get_campaign_role_person_list(c.campaign_id, 'Informatics'::text, 'USERNAME'::text) AS informatics_staff,
    t_research_team.collaborators,
    c.comment,
    c.state,
    c.description,
    c.external_links,
    c.epr_list,
    c.eus_proposal_list,
    c.fraction_emsl_funded,
    eut.eus_usage_type,
    c.organisms,
    c.experiment_prefixes,
    t_data_release_restrictions.release_restriction AS data_release_restriction
   FROM (((public.t_campaign c
     JOIN public.t_data_release_restrictions ON ((c.data_release_restriction_id = t_data_release_restrictions.release_restriction_id)))
     JOIN public.t_eus_usage_type eut ON ((c.eus_usage_type_id = eut.eus_usage_type_id)))
     LEFT JOIN public.t_research_team ON ((c.research_team = t_research_team.team_id)));


ALTER VIEW public.v_campaign_entry OWNER TO d3l243;

--
-- Name: TABLE v_campaign_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_campaign_entry TO readaccess;
GRANT SELECT ON TABLE public.v_campaign_entry TO writeaccess;

