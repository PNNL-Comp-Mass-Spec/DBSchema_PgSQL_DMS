--
-- Name: t_run_interval; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_run_interval (
    interval_id integer NOT NULL,
    instrument public.citext NOT NULL,
    start timestamp without time zone,
    "interval" integer,
    comment public.citext,
    usage xml,
    entered timestamp without time zone,
    last_affected timestamp without time zone,
    entered_by public.citext
);


ALTER TABLE public.t_run_interval OWNER TO d3l243;

--
-- Name: TABLE t_run_interval; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_run_interval TO readaccess;

