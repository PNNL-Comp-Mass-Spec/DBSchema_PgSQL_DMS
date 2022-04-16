--
-- Name: t_notification_event_type; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_notification_event_type (
    event_type_id integer NOT NULL,
    event_type public.citext NOT NULL,
    target_entity_type integer NOT NULL,
    link_template public.citext,
    visible character(1) NOT NULL
);


ALTER TABLE public.t_notification_event_type OWNER TO d3l243;

--
-- Name: TABLE t_notification_event_type; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_notification_event_type TO readaccess;

