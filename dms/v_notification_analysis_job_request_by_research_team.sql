--
-- Name: v_notification_analysis_job_request_by_research_team; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_notification_analysis_job_request_by_research_team AS
 SELECT DISTINCT tne.entry_id AS seq,
    tet.event_type AS event,
    ajr.request_id AS entity,
    ajr.request_name AS name,
    t.campaign,
    t.name AS person,
    public.get_research_team_user_role_list(t.team_id, t.user_id) AS person_role,
    tne.entered,
    tet.target_entity_type AS "#EntityType",
    t."#PRN",
    tet.event_type,
    tne.event_type_id,
    tet.link_template
   FROM ((((public.t_notification_event tne
     JOIN public.t_notification_event_type tet ON ((tet.event_type_id = tne.event_type_id)))
     JOIN public.t_analysis_job_request ajr ON ((tne.target_id = ajr.request_id)))
     JOIN public.t_analysis_job j ON ((ajr.request_id = j.request_id)))
     JOIN ( SELECT t_dataset.dataset_id,
            t_dataset.dataset,
            t_campaign.campaign,
            t_users.name,
            t_users.username AS "#PRN",
            srtm.team_id,
            srtm.user_id
           FROM ((((((public.t_dataset
             JOIN public.t_experiments ON ((t_dataset.exp_id = t_experiments.exp_id)))
             JOIN public.t_campaign ON ((t_experiments.campaign_id = t_campaign.campaign_id)))
             JOIN public.t_research_team ON ((t_campaign.research_team = t_research_team.team_id)))
             JOIN public.t_research_team_membership srtm ON ((t_research_team.team_id = srtm.team_id)))
             JOIN public.t_users ON ((srtm.user_id = t_users.user_id)))
             JOIN public.t_research_team_roles srtr ON ((srtm.role_id = srtr.role_id)))
          WHERE ((t_campaign.state OPERATOR(public.=) 'Active'::public.citext) AND (t_users.active OPERATOR(public.=) 'Y'::public.citext))) t ON ((t.dataset_id = j.dataset_id)))
  WHERE ((tet.target_entity_type = 2) AND (tet.visible = 'Y'::bpchar));


ALTER TABLE public.v_notification_analysis_job_request_by_research_team OWNER TO d3l243;

--
-- Name: TABLE v_notification_analysis_job_request_by_research_team; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_notification_analysis_job_request_by_research_team TO readaccess;

