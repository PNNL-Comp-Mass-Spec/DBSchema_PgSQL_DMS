--
-- Name: v_staff_roles_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_staff_roles_list_report AS
 SELECT u.name AS person,
    roles.role,
    c.campaign,
    c.state,
    c.project,
    team.collaborators,
    campaigntracking.most_recent_activity
   FROM (((((public.t_research_team team
     JOIN public.t_research_team_membership teammembers ON ((team.team_id = teammembers.team_id)))
     JOIN public.t_research_team_roles roles ON ((teammembers.role_id = roles.role_id)))
     JOIN public.t_users u ON ((teammembers.user_id = u.user_id)))
     JOIN public.t_campaign c ON ((team.team_id = c.research_team)))
     LEFT JOIN public.t_campaign_tracking campaigntracking ON ((c.campaign_id = campaigntracking.campaign_id)));


ALTER TABLE public.v_staff_roles_list_report OWNER TO d3l243;

--
-- Name: TABLE v_staff_roles_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_staff_roles_list_report TO readaccess;

