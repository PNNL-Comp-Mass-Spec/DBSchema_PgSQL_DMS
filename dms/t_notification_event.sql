--
-- Name: t_notification_event; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_notification_event (
    entry_id integer NOT NULL,
    event_type_id integer NOT NULL,
    target_id integer NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_notification_event OWNER TO d3l243;

--
-- Name: t_notification_event_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_notification_event ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_notification_event_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_notification_event pk_t_notification_event; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_notification_event
    ADD CONSTRAINT pk_t_notification_event PRIMARY KEY (entry_id);

--
-- Name: t_notification_event fk_t_notification_event_t_notification_event_type; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_notification_event
    ADD CONSTRAINT fk_t_notification_event_t_notification_event_type FOREIGN KEY (event_type_id) REFERENCES public.t_notification_event_type(event_type_id);

--
-- Name: TABLE t_notification_event; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_notification_event TO readaccess;

