--
-- Name: t_instrument_class; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_class (
    instrument_class public.citext NOT NULL,
    is_purgeable smallint NOT NULL,
    raw_data_type public.citext NOT NULL,
    requires_preparation smallint NOT NULL,
    params xml,
    comment public.citext
);


ALTER TABLE public.t_instrument_class OWNER TO d3l243;

--
-- Name: TABLE t_instrument_class; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_class TO readaccess;

