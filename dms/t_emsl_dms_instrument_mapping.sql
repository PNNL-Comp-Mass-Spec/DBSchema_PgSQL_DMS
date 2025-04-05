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

ALTER TABLE public.t_emsl_dms_instrument_mapping CLUSTER ON pk_t_emsl_dms_instrument_mapping;

--
-- Name: ix_t_emsl_dms_instrument_mapping_dms_inst_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_emsl_dms_instrument_mapping_dms_inst_id ON public.t_emsl_dms_instrument_mapping USING btree (dms_instrument_id);

--
-- Name: t_emsl_dms_instrument_mapping fk_t_emsl_dms_instrument_mapping_t_emsl_instruments; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_emsl_dms_instrument_mapping
    ADD CONSTRAINT fk_t_emsl_dms_instrument_mapping_t_emsl_instruments FOREIGN KEY (eus_instrument_id) REFERENCES public.t_emsl_instruments(eus_instrument_id);

--
-- Name: t_emsl_dms_instrument_mapping fk_t_emsl_dms_instrument_mapping_t_instrument_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_emsl_dms_instrument_mapping
    ADD CONSTRAINT fk_t_emsl_dms_instrument_mapping_t_instrument_name FOREIGN KEY (dms_instrument_id) REFERENCES public.t_instrument_name(instrument_id);

--
-- Name: TABLE t_emsl_dms_instrument_mapping; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_emsl_dms_instrument_mapping TO readaccess;
GRANT SELECT ON TABLE public.t_emsl_dms_instrument_mapping TO writeaccess;

