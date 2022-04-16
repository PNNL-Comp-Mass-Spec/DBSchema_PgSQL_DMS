--
-- Name: t_factor_log; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_factor_log (
    event_id integer NOT NULL,
    changed_on timestamp without time zone NOT NULL,
    changed_by public.citext NOT NULL,
    changes public.citext NOT NULL
);


ALTER TABLE public.t_factor_log OWNER TO d3l243;

--
-- Name: TABLE t_factor_log; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_factor_log TO readaccess;

