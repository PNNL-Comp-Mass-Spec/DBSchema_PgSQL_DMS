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
-- Name: t_event_log_index_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_event_log ALTER COLUMN index ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_event_log_index_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_event_log pk_t_event_log; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_event_log
    ADD CONSTRAINT pk_t_event_log PRIMARY KEY (index);

--
-- Name: TABLE t_event_log; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_event_log TO readaccess;

