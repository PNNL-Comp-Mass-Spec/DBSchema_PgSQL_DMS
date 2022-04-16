--
-- Name: t_event_log; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_event_log (
    index integer NOT NULL,
    target_type integer,
    target_id integer,
    target_state smallint,
    prev_target_state smallint,
    entered timestamp without time zone,
    entered_by public.citext
);


ALTER TABLE public.t_event_log OWNER TO d3l243;

--
-- Name: TABLE t_event_log; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_event_log TO readaccess;

