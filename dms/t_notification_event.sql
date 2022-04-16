--
-- Name: t_notification_event; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_notification_event (
    entry_id integer NOT NULL,
    event_type_id integer NOT NULL,
    target_id integer NOT NULL,
    entered timestamp without time zone NOT NULL
);


ALTER TABLE public.t_notification_event OWNER TO d3l243;

--
-- Name: TABLE t_notification_event; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_notification_event TO readaccess;

