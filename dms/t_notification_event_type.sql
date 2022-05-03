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
-- Name: t_notification_event_type pk_t_notification_event_type; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_notification_event_type
    ADD CONSTRAINT pk_t_notification_event_type PRIMARY KEY (event_type_id);

--
-- Name: TABLE t_notification_event_type; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_notification_event_type TO readaccess;

