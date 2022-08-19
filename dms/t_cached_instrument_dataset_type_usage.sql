--
-- Name: t_cached_instrument_dataset_type_usage; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_cached_instrument_dataset_type_usage (
    entry_id integer NOT NULL,
    instrument_id integer NOT NULL,
    dataset_type public.citext NOT NULL,
    dataset_usage_count integer DEFAULT 0,
    dataset_usage_last_year integer DEFAULT 0
);


ALTER TABLE public.t_cached_instrument_dataset_type_usage OWNER TO d3l243;

--
-- Name: t_cached_instrument_dataset_type_usage_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_cached_instrument_dataset_type_usage ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_cached_instrument_dataset_type_usage_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_cached_instrument_dataset_type_usage pk_t_cached_instrument_dataset_type_usage; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_instrument_dataset_type_usage
    ADD CONSTRAINT pk_t_cached_instrument_dataset_type_usage PRIMARY KEY (entry_id);

--
-- Name: ix_t_cached_instrument_dataset_type_usage_unique_inst_ds_type; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_cached_instrument_dataset_type_usage_unique_inst_ds_type ON public.t_cached_instrument_dataset_type_usage USING btree (instrument_id, dataset_type);

--
-- Name: t_cached_instrument_dataset_type_usage fk_t_cached_instrument_dataset_type_usage_t_dataset_type_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_instrument_dataset_type_usage
    ADD CONSTRAINT fk_t_cached_instrument_dataset_type_usage_t_dataset_type_name FOREIGN KEY (dataset_type) REFERENCES public.t_dataset_type_name(dataset_type) ON UPDATE CASCADE;

--
-- Name: t_cached_instrument_dataset_type_usage fk_t_cached_instrument_dataset_type_usage_t_instrument_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_instrument_dataset_type_usage
    ADD CONSTRAINT fk_t_cached_instrument_dataset_type_usage_t_instrument_name FOREIGN KEY (instrument_id) REFERENCES public.t_instrument_name(instrument_id) ON UPDATE CASCADE;

--
-- Name: TABLE t_cached_instrument_dataset_type_usage; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_instrument_dataset_type_usage TO readaccess;
GRANT SELECT ON TABLE public.t_cached_instrument_dataset_type_usage TO writeaccess;

