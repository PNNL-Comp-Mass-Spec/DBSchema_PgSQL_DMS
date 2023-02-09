--
-- Name: v_notification_requested_run_batches_by_research_team; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_notification_requested_run_batches_by_research_team AS
 SELECT DISTINCT tne.entry_id AS seq,
    tet.event_type AS event,
    rrb.batch_id AS entity,
    rrb.batch AS name,
    t.campaign,
    t.name AS person,
    public.get_research_team_user_role_list(t.team_id, t.user_id) AS person_role,
    tne.entered,
    tet.target_entity_type AS entity_type,
    t.username,
    tet.event_type,
    tne.event_type_id,
    tet.link_template
   FROM ((((public.t_notification_event tne
     JOIN public.t_notification_event_type tet ON ((tet.event_type_id = tne.event_type_id)))
     JOIN public.t_requested_run_batches rrb ON ((tne.target_id = rrb.batch_id)))
     JOIN public.t_requested_run rr ON ((rrb.batch_id = rr.batch_id)))
     JOIN ( SELECT ds.dataset_id,
            ds.dataset,
            c.campaign,
            u.name,
            u.username,
            srtm.team_id,
            srtm.user_id
           FROM ((((((public.t_dataset ds
             JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
             JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
             JOIN public.t_research_team ON ((c.research_team = t_research_team.team_id)))
             JOIN public.t_research_team_membership srtm ON ((t_research_team.team_id = srtm.team_id)))
             JOIN public.t_users u ON ((srtm.user_id = u.user_id)))
             JOIN public.t_research_team_roles srtr ON ((srtm.role_id = srtr.role_id)))
          WHERE ((c.state OPERATOR(public.=) 'Active'::public.citext) AND (u.active OPERATOR(public.=) 'Y'::public.citext))) t ON ((t.dataset_id = rr.dataset_id)))
  WHERE ((tet.target_entity_type = 1) AND (tet.visible = 'Y'::bpchar) AND (rrb.batch_id <> 0));


ALTER TABLE public.v_notification_requested_run_batches_by_research_team OWNER TO d3l243;

--
-- Name: TABLE v_notification_requested_run_batches_by_research_team; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_notification_requested_run_batches_by_research_team TO readaccess;
GRANT SELECT ON TABLE public.v_notification_requested_run_batches_by_research_team TO writeaccess;

