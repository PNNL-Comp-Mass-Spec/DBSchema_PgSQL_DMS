--
-- Name: v_notification_sample_prep_request_by_research_team; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_notification_sample_prep_request_by_research_team AS
 SELECT DISTINCT tne.entry_id AS seq,
    tet.event_type AS event,
    t_sample_prep_request.prep_request_id AS entity,
    t_sample_prep_request.request_name AS name,
    t.campaign,
    t.name AS "User",
    t.role AS "Role",
    tne.entered,
    tet.target_entity_type AS "#EntityType",
    t."#PRN",
    tet.event_type,
    tne.event_type_id,
    tet.link_template
   FROM ((((public.t_notification_event tne
     JOIN public.t_notification_event_type tet ON ((tet.event_type_id = tne.event_type_id)))
     JOIN public.t_sample_prep_request ON ((tne.target_id = t_sample_prep_request.prep_request_id)))
     JOIN public.t_sample_prep_request_state_name ON ((t_sample_prep_request.state_id = t_sample_prep_request_state_name.state_id)))
     JOIN ( SELECT t_campaign.campaign,
            t_users.name,
            public.get_research_team_user_role_list(srtm.team_id, srtm.user_id) AS role,
            t_users.username AS "#PRN"
           FROM ((((public.t_campaign
             JOIN public.t_research_team ON ((t_campaign.research_team = t_research_team.team_id)))
             JOIN public.t_research_team_membership srtm ON ((t_research_team.team_id = srtm.team_id)))
             JOIN public.t_users ON ((srtm.user_id = t_users.user_id)))
             JOIN public.t_research_team_roles srtr ON ((srtm.role_id = srtr.role_id)))
          WHERE ((t_campaign.state OPERATOR(public.=) 'Active'::public.citext) AND (t_users.active OPERATOR(public.=) 'Y'::public.citext))) t ON ((t.campaign OPERATOR(public.=) t_sample_prep_request.campaign)))
  WHERE ((tet.target_entity_type = 3) AND (tet.visible = 'Y'::bpchar));


ALTER TABLE public.v_notification_sample_prep_request_by_research_team OWNER TO d3l243;

--
-- Name: TABLE v_notification_sample_prep_request_by_research_team; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_notification_sample_prep_request_by_research_team TO readaccess;

