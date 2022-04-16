--
-- Name: t_email_alert_state; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_email_alert_state (
    alert_state smallint NOT NULL,
    alert_state_name public.citext
);


ALTER TABLE public.t_email_alert_state OWNER TO d3l243;

--
-- Name: TABLE t_email_alert_state; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_email_alert_state TO readaccess;

