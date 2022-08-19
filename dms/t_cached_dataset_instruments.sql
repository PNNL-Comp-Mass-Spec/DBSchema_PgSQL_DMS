--
-- Name: t_cached_dataset_instruments; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_cached_dataset_instruments (
    dataset_id integer NOT NULL,
    instrument_id integer NOT NULL,
    instrument public.citext NOT NULL
);


ALTER TABLE public.t_cached_dataset_instruments OWNER TO d3l243;

--
-- Name: t_cached_dataset_instruments pk_t_cached_dataset_instruments; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_dataset_instruments
    ADD CONSTRAINT pk_t_cached_dataset_instruments PRIMARY KEY (dataset_id);

--
-- Name: ix_t_cached_dataset_instruments_instrument_id_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_cached_dataset_instruments_instrument_id_dataset_id ON public.t_cached_dataset_instruments USING btree (instrument_id, dataset_id);

--
-- Name: ix_t_cached_dataset_instruments_instrument_name_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_cached_dataset_instruments_instrument_name_dataset_id ON public.t_cached_dataset_instruments USING btree (instrument, dataset_id);

--
-- Name: t_cached_dataset_instruments fk_t_cached_dataset_instruments_t_dataset; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_dataset_instruments
    ADD CONSTRAINT fk_t_cached_dataset_instruments_t_dataset FOREIGN KEY (dataset_id) REFERENCES public.t_dataset(dataset_id);

--
-- Name: t_cached_dataset_instruments fk_t_cached_dataset_instruments_t_instrument_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_dataset_instruments
    ADD CONSTRAINT fk_t_cached_dataset_instruments_t_instrument_name FOREIGN KEY (instrument_id) REFERENCES public.t_instrument_name(instrument_id);

--
-- Name: TABLE t_cached_dataset_instruments; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_dataset_instruments TO readaccess;
GRANT SELECT ON TABLE public.t_cached_dataset_instruments TO writeaccess;

