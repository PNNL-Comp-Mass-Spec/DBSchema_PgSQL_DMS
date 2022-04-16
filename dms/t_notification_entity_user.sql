--
-- Name: t_notification_entity_user; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_notification_entity_user (
    user_id integer NOT NULL,
    entity_type_id integer NOT NULL
);


ALTER TABLE public.t_notification_entity_user OWNER TO d3l243;

--
-- Name: TABLE t_notification_entity_user; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_notification_entity_user TO readaccess;

