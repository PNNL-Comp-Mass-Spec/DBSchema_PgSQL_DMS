--
-- Name: t_email_alerts; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_email_alerts (
    email_alert_id integer NOT NULL,
    posted_by public.citext NOT NULL,
    posting_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    alert_type public.citext DEFAULT 'Error'::public.citext NOT NULL,
    message public.citext NOT NULL,
    recipients public.citext NOT NULL,
    alert_state smallint DEFAULT 1 NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_email_alerts OWNER TO d3l243;

--
-- Name: t_email_alerts_email_alert_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_email_alerts ALTER COLUMN email_alert_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_email_alerts_email_alert_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_email_alerts pk_t_email_alerts; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_email_alerts
    ADD CONSTRAINT pk_t_email_alerts PRIMARY KEY (email_alert_id);

ALTER TABLE public.t_email_alerts CLUSTER ON pk_t_email_alerts;

--
-- Name: t_email_alerts fk_t_email_alerts_t_email_alert_state; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_email_alerts
    ADD CONSTRAINT fk_t_email_alerts_t_email_alert_state FOREIGN KEY (alert_state) REFERENCES public.t_email_alert_state(alert_state);

--
-- Name: TABLE t_email_alerts; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_email_alerts TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_email_alerts TO writeaccess;

