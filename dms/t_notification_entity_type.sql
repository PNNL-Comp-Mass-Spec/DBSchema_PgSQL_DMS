--
-- Name: t_notification_entity_type; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_notification_entity_type (
    entity_type_id integer NOT NULL,
    entity_type public.citext NOT NULL
);


ALTER TABLE public.t_notification_entity_type OWNER TO d3l243;

--
-- Name: TABLE t_notification_entity_type; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_notification_entity_type TO readaccess;

