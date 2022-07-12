--
-- Name: v_email_alerts; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_email_alerts AS
 SELECT alerts.email_alert_id AS id,
    alerts.posted_by,
    alerts.posting_time,
    alerts.alert_type,
    alerts.message,
    alerts.recipients,
    alerts.alert_state,
    alertstate.alert_state_name,
    alerts.last_affected
   FROM (public.t_email_alerts alerts
     JOIN public.t_email_alert_state alertstate ON ((alerts.alert_state = alertstate.alert_state)));


ALTER TABLE public.v_email_alerts OWNER TO d3l243;

--
-- Name: TABLE v_email_alerts; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_email_alerts TO readaccess;

