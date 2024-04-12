--
-- Name: v_notification_event_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_notification_event_list_report AS
 SELECT ne.entry_id AS id,
    eventtype.event_type AS event,
    ne.target_id AS entity,
    ne.entered,
    eventtype.target_entity_type AS entity_type
   FROM (public.t_notification_event ne
     JOIN public.t_notification_event_type eventtype ON ((ne.event_type_id = eventtype.event_type_id)));


ALTER VIEW public.v_notification_event_list_report OWNER TO d3l243;

--
-- Name: TABLE v_notification_event_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_notification_event_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_notification_event_list_report TO writeaccess;

