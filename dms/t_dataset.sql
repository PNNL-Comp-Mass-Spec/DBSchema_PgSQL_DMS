--
-- Name: t_dataset; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset (
    dataset_id integer NOT NULL,
    dataset public.citext NOT NULL,
    operator_prn public.citext NOT NULL,
    comment public.citext,
    created timestamp without time zone NOT NULL,
    instrument_id integer,
    lc_column_id integer DEFAULT 0,
    dataset_type_id integer,
    wellplate public.citext DEFAULT 'na'::public.citext,
    well public.citext,
    separation_type public.citext,
    ds_state_id integer DEFAULT 1 NOT NULL,
    last_affected timestamp without time zone NOT NULL,
    folder_name public.citext,
    storage_path_id integer,
    exp_id integer NOT NULL,
    internal_standard_id integer DEFAULT 0,
    dataset_rating_id smallint DEFAULT 2 NOT NULL,
    ds_comp_state smallint,
    ds_compress_date timestamp without time zone,
    ds_prep_server_name public.citext DEFAULT 'na'::public.citext NOT NULL,
    acq_time_start timestamp without time zone,
    acq_time_end timestamp without time zone,
    scan_count integer,
    file_size_bytes bigint,
    file_info_last_modified timestamp without time zone,
    interval_to_next_ds integer,
    acq_length_minutes integer GENERATED ALWAYS AS (COALESCE((EXTRACT(epoch FROM (acq_time_end - acq_time_start)) / (60)::numeric), (0)::numeric)) STORED,
    date_sort_key timestamp without time zone NOT NULL,
    decon_tools_job_for_qc integer,
    capture_subfolder public.citext,
    cart_config_id integer
);


ALTER TABLE public.t_dataset OWNER TO d3l243;

--
-- Name: t_dataset pk_t_dataset; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset
    ADD CONSTRAINT pk_t_dataset PRIMARY KEY (dataset_id);

--
-- Name: ix_t_dataset_acq_time_start; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_acq_time_start ON public.t_dataset USING btree (acq_time_start);

--
-- Name: ix_t_dataset_cart_config_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_cart_config_id ON public.t_dataset USING btree (cart_config_id);

--
-- Name: ix_t_dataset_created; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_created ON public.t_dataset USING btree (created);

--
-- Name: ix_t_dataset_dataset; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_dataset_dataset ON public.t_dataset USING btree (dataset);

--
-- Name: ix_t_dataset_dataset_id_created; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_dataset_id_created ON public.t_dataset USING btree (dataset_id, created) INCLUDE (dataset);

--
-- Name: ix_t_dataset_dataset_id_created_storage_path_id_include; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_dataset_id_created_storage_path_id_include ON public.t_dataset USING btree (dataset_id, created, storage_path_id) INCLUDE (dataset);

--
-- Name: ix_t_dataset_dataset_id_exp_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_dataset_id_exp_id ON public.t_dataset USING btree (dataset_id, exp_id);

--
-- Name: ix_t_dataset_dataset_id_include_dataset_instrument_name_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_dataset_id_include_dataset_instrument_name_id ON public.t_dataset USING btree (dataset_id) INCLUDE (dataset, instrument_id);

--
-- Name: ix_t_dataset_dataset_id_instrument_name_id_storage_path_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_dataset_id_instrument_name_id_storage_path_id ON public.t_dataset USING btree (dataset_id, instrument_id, storage_path_id);

--
-- Name: ix_t_dataset_date_sort_key; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_date_sort_key ON public.t_dataset USING btree (date_sort_key);

--
-- Name: ix_t_dataset_exp_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_exp_id ON public.t_dataset USING btree (exp_id);

--
-- Name: ix_t_dataset_id_created_exp_id_spath_id_instrument_name_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_id_created_exp_id_spath_id_instrument_name_id ON public.t_dataset USING btree (dataset_id, created, exp_id, storage_path_id, instrument_id);

--
-- Name: ix_t_dataset_inst_name_id_dataset_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_inst_name_id_dataset_dataset_id ON public.t_dataset USING btree (instrument_id, dataset, dataset_id);

--
-- Name: ix_t_dataset_instrument_id_state_id_include_dataset_name_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_instrument_id_state_id_include_dataset_name_id ON public.t_dataset USING btree (instrument_id, ds_state_id) INCLUDE (dataset, dataset_id);

--
-- Name: ix_t_dataset_instrument_name_id_acq_time_start_include_dataset; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_instrument_name_id_acq_time_start_include_dataset ON public.t_dataset USING btree (instrument_id, acq_time_start) INCLUDE (dataset_id, dataset_rating_id);

--
-- Name: ix_t_dataset_instrument_name_id_type_id_include_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_instrument_name_id_type_id_include_dataset_id ON public.t_dataset USING btree (instrument_id, dataset_type_id) INCLUDE (dataset_id);

--
-- Name: ix_t_dataset_lc_column_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_lc_column_id ON public.t_dataset USING btree (lc_column_id);

--
-- Name: ix_t_dataset_rating_include_instrument_id_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_rating_include_instrument_id_dataset_id ON public.t_dataset USING btree (dataset_rating_id) INCLUDE (instrument_id, dataset_id);

--
-- Name: ix_t_dataset_sec_sep; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_sec_sep ON public.t_dataset USING btree (separation_type) INCLUDE (created, dataset_id);

--
-- Name: ix_t_dataset_state_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_state_id ON public.t_dataset USING btree (ds_state_id);

--
-- Name: ix_t_dataset_storage_path_id_created_instrument_name_id_rating; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_storage_path_id_created_instrument_name_id_rating ON public.t_dataset USING btree (storage_path_id, created, instrument_id, dataset_rating_id, dataset_id);

--
-- Name: t_dataset fk_t_dataset_t_dataset_rating_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset
    ADD CONSTRAINT fk_t_dataset_t_dataset_rating_name FOREIGN KEY (dataset_rating_id) REFERENCES public.t_dataset_rating_name(dataset_rating_id);

--
-- Name: t_dataset fk_t_dataset_t_dataset_state_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset
    ADD CONSTRAINT fk_t_dataset_t_dataset_state_name FOREIGN KEY (ds_state_id) REFERENCES public.t_dataset_state_name(ds_state_id);

--
-- Name: t_dataset fk_t_dataset_t_dataset_type_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset
    ADD CONSTRAINT fk_t_dataset_t_dataset_type_name FOREIGN KEY (dataset_type_id) REFERENCES public.t_dataset_type_name(dataset_type_id) ON UPDATE CASCADE;

--
-- Name: t_dataset fk_t_dataset_t_experiments; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset
    ADD CONSTRAINT fk_t_dataset_t_experiments FOREIGN KEY (exp_id) REFERENCES public.t_experiments(exp_id);

--
-- Name: t_dataset fk_t_dataset_t_instrument_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset
    ADD CONSTRAINT fk_t_dataset_t_instrument_name FOREIGN KEY (instrument_id) REFERENCES public.t_instrument_name(instrument_id);

--
-- Name: t_dataset fk_t_dataset_t_internal_standards; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset
    ADD CONSTRAINT fk_t_dataset_t_internal_standards FOREIGN KEY (internal_standard_id) REFERENCES public.t_internal_standards(internal_standard_id);

--
-- Name: t_dataset fk_t_dataset_t_lc_cart_configuration; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset
    ADD CONSTRAINT fk_t_dataset_t_lc_cart_configuration FOREIGN KEY (cart_config_id) REFERENCES public.t_lc_cart_configuration(cart_config_id);

--
-- Name: t_dataset fk_t_dataset_t_lc_column; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset
    ADD CONSTRAINT fk_t_dataset_t_lc_column FOREIGN KEY (lc_column_id) REFERENCES public.t_lc_column(lc_column_id);

--
-- Name: t_dataset fk_t_dataset_t_secondary_sep; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset
    ADD CONSTRAINT fk_t_dataset_t_secondary_sep FOREIGN KEY (separation_type) REFERENCES public.t_secondary_sep(separation_type) ON UPDATE CASCADE;

--
-- Name: t_dataset fk_t_dataset_t_storage_path; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset
    ADD CONSTRAINT fk_t_dataset_t_storage_path FOREIGN KEY (storage_path_id) REFERENCES public.t_storage_path(storage_path_id) ON UPDATE CASCADE;

--
-- Name: t_dataset fk_t_dataset_t_users; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset
    ADD CONSTRAINT fk_t_dataset_t_users FOREIGN KEY (operator_prn) REFERENCES public.t_users(prn) ON UPDATE CASCADE;

--
-- Name: TABLE t_dataset; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset TO readaccess;

