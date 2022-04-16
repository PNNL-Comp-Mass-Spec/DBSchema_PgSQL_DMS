--
-- Name: t_emsl_instrument_usage_type; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_emsl_instrument_usage_type (
    usage_type_id smallint NOT NULL,
    usage_type public.citext NOT NULL,
    description public.citext,
    enabled smallint NOT NULL
);


ALTER TABLE public.t_emsl_instrument_usage_type OWNER TO d3l243;

--
-- Name: TABLE t_emsl_instrument_usage_type; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_emsl_instrument_usage_type TO readaccess;

