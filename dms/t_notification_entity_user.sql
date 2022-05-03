--
-- Name: t_notification_entity_user; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_notification_entity_user (
    user_id integer NOT NULL,
    entity_type_id integer NOT NULL
);


ALTER TABLE public.t_notification_entity_user OWNER TO d3l243;

--
-- Name: t_notification_entity_user pk_t_notification_entity_user; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_notification_entity_user
    ADD CONSTRAINT pk_t_notification_entity_user PRIMARY KEY (user_id, entity_type_id);

--
-- Name: TABLE t_notification_entity_user; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_notification_entity_user TO readaccess;

