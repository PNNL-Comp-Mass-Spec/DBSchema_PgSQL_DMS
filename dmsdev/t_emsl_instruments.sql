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
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    eus_active_sw public.citext,
    eus_primary_instrument public.citext
);


ALTER TABLE public.t_emsl_instruments OWNER TO d3l243;

--
-- Name: t_emsl_instruments pk_t_emsl_instruments; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_emsl_instruments
    ADD CONSTRAINT pk_t_emsl_instruments PRIMARY KEY (eus_instrument_id);

--
-- Name: TABLE t_emsl_instruments; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_emsl_instruments TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_emsl_instruments TO writeaccess;

