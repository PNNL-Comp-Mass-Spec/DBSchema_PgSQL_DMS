--
-- Name: v_notification_analysis_job_request_by_request_owner; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_notification_analysis_job_request_by_request_owner AS
 SELECT DISTINCT tne.entry_id AS seq,
    tet.event_type AS event,
    ajr.request_id AS entity,
    ajr.request_name AS name,
    c.campaign,
    u.name AS person,
    'Request Owner'::text AS person_role,
    tne.entered,
    tet.target_entity_type AS entity_type,
    u.username,
    tet.event_type,
    tne.event_type_id,
    tet.link_template
   FROM (((((((public.t_notification_event tne
     JOIN public.t_notification_event_type tet ON ((tet.event_type_id = tne.event_type_id)))
     JOIN public.t_analysis_job_request ajr ON ((tne.target_id = ajr.request_id)))
     JOIN public.t_analysis_job j ON ((ajr.request_id = j.request_id)))
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_users u ON ((ajr.user_id = u.user_id)))
  WHERE ((tet.target_entity_type = 2) AND (tet.visible = 'Y'::bpchar) AND (u.active OPERATOR(public.=) 'Y'::public.citext));


ALTER TABLE public.v_notification_analysis_job_request_by_request_owner OWNER TO d3l243;

--
-- Name: TABLE v_notification_analysis_job_request_by_request_owner; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_notification_analysis_job_request_by_request_owner TO readaccess;
GRANT SELECT ON TABLE public.v_notification_analysis_job_request_by_request_owner TO writeaccess;

