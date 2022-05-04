--
-- Name: t_requested_run; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_requested_run (
    request_id integer NOT NULL,
    request_name public.citext NOT NULL,
    requester_prn public.citext NOT NULL,
    comment public.citext,
    created timestamp without time zone NOT NULL,
    instrument_group public.citext,
    request_type_id integer,
    instrument_setting public.citext,
    special_instructions public.citext,
    wellplate public.citext,
    well public.citext,
    priority smallint,
    note public.citext,
    exp_id integer NOT NULL,
    request_run_start timestamp without time zone,
    request_run_finish timestamp without time zone,
    request_internal_standard public.citext,
    work_package public.citext,
    batch_id integer DEFAULT 0 NOT NULL,
    blocking_factor public.citext,
    block integer,
    run_order integer,
    eus_proposal_id public.citext,
    eus_usage_type_id smallint DEFAULT 1 NOT NULL,
    cart_id integer DEFAULT 1 NOT NULL,
    cart_config_id integer,
    cart_column smallint,
    separation_group public.citext DEFAULT 'none'::public.citext,
    mrm_attachment integer,
    dataset_id integer,
    origin public.citext NOT NULL,
    state_name public.citext DEFAULT 'Active'::public.citext NOT NULL,
    request_name_code public.citext,
    vialing_conc public.citext,
    vialing_vol public.citext,
    location_id integer,
    queue_state smallint DEFAULT 1 NOT NULL,
    queue_instrument_id integer,
    queue_date timestamp without time zone,
    entered timestamp without time zone,
    updated timestamp without time zone
);


ALTER TABLE public.t_requested_run OWNER TO d3l243;

--
-- Name: t_requested_run pk_t_requested_run; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT pk_t_requested_run PRIMARY KEY (request_id);

--
-- Name: ix_t_requested_run_batch_id_include_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_batch_id_include_dataset_id ON public.t_requested_run USING btree (batch_id) INCLUDE (dataset_id);

--
-- Name: ix_t_requested_run_batch_id_include_exp_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_batch_id_include_exp_id ON public.t_requested_run USING btree (batch_id) INCLUDE (exp_id);

--
-- Name: ix_t_requested_run_block_include_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_block_include_id ON public.t_requested_run USING btree (block) INCLUDE (request_id);

--
-- Name: ix_t_requested_run_created; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_created ON public.t_requested_run USING btree (created);

--
-- Name: ix_t_requested_run_dataset_id_include_created_id_batch; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_dataset_id_include_created_id_batch ON public.t_requested_run USING btree (dataset_id) INCLUDE (created, request_id, batch_id);

--
-- Name: ix_t_requested_run_dataset_id_status; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_dataset_id_status ON public.t_requested_run USING btree (dataset_id, state_name);

--
-- Name: ix_t_requested_run_eus_proposal_id_include_id_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_eus_proposal_id_include_id_dataset_id ON public.t_requested_run USING btree (eus_proposal_id) INCLUDE (request_id, dataset_id);

--
-- Name: ix_t_requested_run_eus_usage_type_include_eus_proposal_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_eus_usage_type_include_eus_proposal_id ON public.t_requested_run USING btree (eus_usage_type_id) INCLUDE (eus_proposal_id, dataset_id);

--
-- Name: ix_t_requested_run_exp_id_include_name_idstatus; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_exp_id_include_name_idstatus ON public.t_requested_run USING btree (exp_id) INCLUDE (request_name, request_id, state_name);

--
-- Name: ix_t_requested_run_name_status_include_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_name_status_include_id ON public.t_requested_run USING btree (request_name, state_name) INCLUDE (request_id);

--
-- Name: ix_t_requested_run_proposal_id_work_package_entered; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_proposal_id_work_package_entered ON public.t_requested_run USING btree (eus_proposal_id, work_package, entered);

--
-- Name: ix_t_requested_run_queue_state_include_request_type_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_queue_state_include_request_type_id ON public.t_requested_run USING btree (queue_state) INCLUDE (request_type_id);

--
-- Name: ix_t_requested_run_request_name_code; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_request_name_code ON public.t_requested_run USING btree (request_name_code);

--
-- Name: ix_t_requested_run_run_order_include_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_run_order_include_id ON public.t_requested_run USING btree (run_order) INCLUDE (request_id);

--
-- Name: ix_t_requested_run_state_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_state_name ON public.t_requested_run USING btree (state_name) INCLUDE (request_id);

--
-- Name: ix_t_requested_run_updated; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_updated ON public.t_requested_run USING btree (updated);

--
-- Name: TABLE t_requested_run; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_requested_run TO readaccess;

