--
-- Name: t_factor; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_factor (
    factor_id integer NOT NULL,
    type public.citext NOT NULL,
    target_id integer NOT NULL,
    name public.citext NOT NULL,
    value public.citext NOT NULL,
    last_updated timestamp without time zone NOT NULL
);


ALTER TABLE public.t_factor OWNER TO d3l243;

--
-- Name: TABLE t_factor; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_factor TO readaccess;

