--
-- Name: v_notification_message_by_registered_users; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_notification_message_by_registered_users AS
 SELECT vnmrt.event,
    vnmrt.entity,
    vnmrt.link,
    vnmrt.name,
    vnmrt.campaign,
    vnmrt.person_role AS role,
    vnmrt.event_type_id,
    vnmrt.entity_type,
    vnmrt.username,
    vnmrt.person,
    tner.user_id,
    vnmrt.entered,
    tu.email
   FROM ((public.t_notification_entity_user tner
     JOIN public.t_users tu ON ((tner.user_id = tu.user_id)))
     JOIN public.v_notification_message_by_research_team vnmrt ON (((tu.username OPERATOR(public.=) vnmrt.username) AND (tner.entity_type_id = vnmrt.entity_type))));


ALTER TABLE public.v_notification_message_by_registered_users OWNER TO d3l243;

--
-- Name: TABLE v_notification_message_by_registered_users; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_notification_message_by_registered_users TO readaccess;
GRANT SELECT ON TABLE public.v_notification_message_by_registered_users TO writeaccess;

