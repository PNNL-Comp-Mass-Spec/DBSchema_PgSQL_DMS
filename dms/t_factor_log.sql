--
-- Name: t_factor_log; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_factor_log (
    event_id integer NOT NULL,
    changed_on timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    changed_by public.citext NOT NULL,
    changes public.citext NOT NULL
);


ALTER TABLE public.t_factor_log OWNER TO d3l243;

--
-- Name: t_factor_log_event_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_factor_log ALTER COLUMN event_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_factor_log_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_factor_log pk_t_factor_log; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_factor_log
    ADD CONSTRAINT pk_t_factor_log PRIMARY KEY (event_id);

ALTER TABLE public.t_factor_log CLUSTER ON pk_t_factor_log;

--
-- Name: TABLE t_factor_log; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_factor_log TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_factor_log TO writeaccess;

