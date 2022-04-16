--
-- Name: t_instrument_ops_role; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_ops_role (
    role public.citext NOT NULL,
    description public.citext
);


ALTER TABLE public.t_instrument_ops_role OWNER TO d3l243;

--
-- Name: TABLE t_instrument_ops_role; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_ops_role TO readaccess;

