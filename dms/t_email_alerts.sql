--
-- Name: t_email_alerts; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_email_alerts (
    email_alert_id integer NOT NULL,
    posted_by public.citext NOT NULL,
    posting_time timestamp without time zone NOT NULL,
    alert_type public.citext NOT NULL,
    message public.citext NOT NULL,
    recipients public.citext NOT NULL,
    alert_state smallint NOT NULL,
    last_affected timestamp without time zone NOT NULL
);


ALTER TABLE public.t_email_alerts OWNER TO d3l243;

--
-- Name: TABLE t_email_alerts; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_email_alerts TO readaccess;

