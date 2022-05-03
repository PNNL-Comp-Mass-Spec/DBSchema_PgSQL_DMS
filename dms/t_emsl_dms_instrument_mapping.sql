--
-- Name: t_emsl_dms_instrument_mapping; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_emsl_dms_instrument_mapping (
    eus_instrument_id integer NOT NULL,
    dms_instrument_id integer NOT NULL
);


ALTER TABLE public.t_emsl_dms_instrument_mapping OWNER TO d3l243;

--
-- Name: t_emsl_dms_instrument_mapping pk_t_emsl_dms_instrument_mapping; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_emsl_dms_instrument_mapping
    ADD CONSTRAINT pk_t_emsl_dms_instrument_mapping PRIMARY KEY (eus_instrument_id, dms_instrument_id);

--
-- Name: TABLE t_emsl_dms_instrument_mapping; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_emsl_dms_instrument_mapping TO readaccess;

