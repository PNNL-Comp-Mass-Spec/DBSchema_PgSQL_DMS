--
-- Name: t_instrument_config_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_config_history (
    entry_id integer NOT NULL,
    instrument public.citext NOT NULL,
    date_of_change timestamp without time zone,
    description public.citext,
    note public.citext,
    entered timestamp without time zone NOT NULL,
    entered_by public.citext NOT NULL
);


ALTER TABLE public.t_instrument_config_history OWNER TO d3l243;

--
-- Name: TABLE t_instrument_config_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_config_history TO readaccess;

