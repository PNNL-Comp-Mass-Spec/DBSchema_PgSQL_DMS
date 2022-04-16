--
-- Name: t_emsl_instruments; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_emsl_instruments (
    eus_instrument_id integer NOT NULL,
    eus_display_name public.citext,
    eus_instrument_name public.citext,
    eus_available_hours public.citext,
    local_category_name public.citext,
    local_instrument_name public.citext,
    last_affected timestamp without time zone,
    eus_active_sw character(1),
    eus_primary_instrument character(1)
);


ALTER TABLE public.t_emsl_instruments OWNER TO d3l243;

--
-- Name: TABLE t_emsl_instruments; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_emsl_instruments TO readaccess;

