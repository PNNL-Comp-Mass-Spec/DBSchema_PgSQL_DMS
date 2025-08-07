--
-- Name: t_requested_run; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_requested_run (
    request_id integer NOT NULL,
    request_name public.citext NOT NULL,
    requester_username public.citext NOT NULL,
    comment public.citext,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
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
    cached_wp_activation_state smallint DEFAULT 0 NOT NULL,
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
    origin public.citext DEFAULT 'user'::public.citext NOT NULL,
    state_name public.citext DEFAULT 'Active'::public.citext NOT NULL,
    request_name_code public.citext,
    vialing_conc public.citext,
    vialing_vol public.citext,
    location_id integer,
    queue_state smallint DEFAULT 1 NOT NULL,
    queue_instrument_id integer,
    queue_date timestamp without time zone,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by public.citext,
    service_type_id smallint DEFAULT 0 NOT NULL,
    CONSTRAINT ck_t_requested_run_request_name_whitespace CHECK ((public.has_whitespace_chars((request_name)::text, false) = false))
);


ALTER TABLE public.t_requested_run OWNER TO d3l243;

--
-- Name: TABLE t_requested_run; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON TABLE public.t_requested_run IS '
For fast lookups on requested run name, utilize index
ix_t_requested_run_request_name_lower_text_pattern_ops,
with queries of the form:

SELECT *
FROM t_requested_run
WHERE Lower(request_name::text) LIKE Lower(''Citric-acid'');

Query performance comparisons:

-- Query 1: no filter
EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT TEXT)
SELECT *
FROM t_requested_run
ORDER BY request_id DESC
LIMIT 125;

Limit (cost=0.43..12.75 rows=125 width=367)
     (actual time=0.052..0.144 rows=125 loops=1)
  ->  Index Scan Backward using pk_t_requested_run on public.t_requested_run
      (cost=0.43..119848.79 rows=1215538 width=367)
      (actual time=0.049..0.119 rows=125 loops=1)
Planning Time: 0.376 ms
Execution Time: 0.246 ms

-- Query 2: filter on request name
EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT TEXT)
SELECT *
FROM t_requested_run
WHERE request_name SIMILAR TO ''NanoPOTS%TMT%Lib%''
ORDER BY request_id DESC
LIMIT 125;

Limit (cost=0.43..2527.72 rows=125 width=367)
      (actual time=15.970..696.066 rows=97 loops=1)
  ->  Index Scan Backward using pk_t_requested_run on public.t_requested_run
      (cost=0.43..122887.64 rows=6078 width=367)
      (actual time=15.967..696.049 rows=97 loops=1)
        Filter: (t_requested_run.request_name ~ ''^(?:NanoPOTS.*TMT.*Lib.*)$''::text)
        Rows Removed by Filter: 1215108
Planning Time: 0.361 ms
Execution Time: 696.164 ms

-- Query 3: when filtering, cast to text and use lower()
EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT TEXT)
SELECT *
FROM t_requested_run
WHERE Lower(request_name::text) SIMILAR TO Lower(''NanoPOTS%TMT%Lib%'')
ORDER BY request_id DESC
LIMIT 125;

Limit (cost=7.01..7.31 rows=122 width=367)
      (actual time=17.074..17.087 rows=97 loops=1)
  ->  Sort
      (cost=7.01..7.31 rows=122 width=367)
      (actual time=17.071..17.077 rows=97 loops=1)
        Sort Key: t_requested_run.request_id DESC
        Sort Method: quicksort  Memory: 74kB
        ->  Index Scan using ix_t_requested_run_request_name_lower_text_pattern_ops
            (cost=0.55..2.78 rows=122 width=367)
            (actual time=9.697..17.015 rows=97 loops=1)
              Index Cond: ((lower((t_requested_run.request_name)::text) ~>=~ ''nanopots''::text) AND
                           (lower((t_requested_run.request_name)::text) ~<~ ''nanopott''::text))
              Filter: (lower((t_requested_run.request_name)::text) ~ ''^(?:nanopots.*tmt.*lib.*)$''::text)
              Rows Removed by Filter: 4873
Planning Time: 1.038 ms
Execution Time: 17.183 ms

-- Query 4: use LIKE instead of SIMILAR TO
EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT TEXT)
SELECT *
FROM t_requested_run
WHERE Lower(request_name::text) LIKE Lower(''NanoPOTS%TMT%Lib%'')
ORDER BY request_id DESC
LIMIT 125;

Limit (cost=7.01..7.31 rows=122 width=367)
      (actual time=8.000..8.013 rows=97 loops=1)
  ->  Sort (cost=7.01..7.31 rows=122 width=367)
           (actual time=7.998..8.004 rows=97 loops=1)
        Sort Key: t_requested_run.request_id DESC
        Sort Method: quicksort  Memory: 74kB
        ->  Index Scan using ix_t_requested_run_request_name_lower_text_pattern_ops
            (cost=0.55..2.78 rows=122 width=367)
            (actual time=4.849..7.951 rows=97 loops=1)
              Index Cond: ((lower((t_requested_run.request_name)::text) ~>=~ ''nanopots''::text) AND
                           (lower((t_requested_run.request_name)::text) ~<~ ''nanopott''::text))
              Filter: (lower((t_requested_run.request_name)::text) ~~ ''nanopots%tmt%lib%''::text)
              Rows Removed by Filter: 4873
Planning Time: 0.665 ms
Execution Time: 8.101 ms
';

--
-- Name: t_requested_run_request_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_requested_run ALTER COLUMN request_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_requested_run_request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_requested_run pk_t_requested_run; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT pk_t_requested_run PRIMARY KEY (request_id);

ALTER TABLE public.t_requested_run CLUSTER ON pk_t_requested_run;

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
-- Name: ix_t_requested_run_cached_wp_act_state_include_request_type_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_cached_wp_act_state_include_request_type_id ON public.t_requested_run USING btree (cached_wp_activation_state) INCLUDE (request_type_id);

--
-- Name: ix_t_requested_run_created; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_created ON public.t_requested_run USING btree (created);

--
-- Name: ix_t_requested_run_dataset_id_include_created_id_batch; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_dataset_id_include_created_id_batch ON public.t_requested_run USING btree (dataset_id) INCLUDE (created, request_id, batch_id);

--
-- Name: ix_t_requested_run_dataset_id_state; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_dataset_id_state ON public.t_requested_run USING btree (dataset_id, state_name);

--
-- Name: ix_t_requested_run_eus_proposal_id_include_id_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_eus_proposal_id_include_id_dataset_id ON public.t_requested_run USING btree (eus_proposal_id) INCLUDE (request_id, dataset_id);

--
-- Name: ix_t_requested_run_eus_usage_type_include_eus_proposal_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_eus_usage_type_include_eus_proposal_id ON public.t_requested_run USING btree (eus_usage_type_id) INCLUDE (eus_proposal_id, dataset_id);

--
-- Name: ix_t_requested_run_exp_id_include_name_id_state; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_exp_id_include_name_id_state ON public.t_requested_run USING btree (exp_id) INCLUDE (request_name, request_id, state_name);

--
-- Name: ix_t_requested_run_instrument_group; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_instrument_group ON public.t_requested_run USING btree (instrument_group);

--
-- Name: ix_t_requested_run_instrument_group_lower_text_pattern_ops; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_instrument_group_lower_text_pattern_ops ON public.t_requested_run USING btree (lower((instrument_group)::text) text_pattern_ops);

--
-- Name: ix_t_requested_run_name_state_include_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_name_state_include_id ON public.t_requested_run USING btree (request_name, state_name) INCLUDE (request_id);

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
-- Name: ix_t_requested_run_request_name_lower_text_pattern_ops; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_request_name_lower_text_pattern_ops ON public.t_requested_run USING btree (lower((request_name)::text) text_pattern_ops);

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
-- Name: ix_t_requested_run_work_package_include_id_cached_wp_act_state; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_work_package_include_id_cached_wp_act_state ON public.t_requested_run USING btree (work_package) INCLUDE (request_id, cached_wp_activation_state);

--
-- Name: t_requested_run trig_t_requested_run_after_delete; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_requested_run_after_delete AFTER DELETE ON public.t_requested_run REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_requested_run_after_delete();

--
-- Name: t_requested_run trig_t_requested_run_after_insert; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_requested_run_after_insert AFTER INSERT ON public.t_requested_run FOR EACH ROW EXECUTE FUNCTION public.trigfn_t_requested_run_after_insert_or_update();

--
-- Name: t_requested_run trig_t_requested_run_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_requested_run_after_update AFTER UPDATE ON public.t_requested_run FOR EACH ROW WHEN (((old.batch_id <> new.batch_id) OR (old.cart_id <> new.cart_id) OR (old.eus_usage_type_id <> new.eus_usage_type_id) OR (old.exp_id <> new.exp_id) OR (old.origin OPERATOR(public.<>) new.origin) OR (old.queue_state <> new.queue_state) OR (old.request_name OPERATOR(public.<>) new.request_name) OR (old.requester_username OPERATOR(public.<>) new.requester_username) OR (old.service_type_id <> new.service_type_id) OR (old.state_name OPERATOR(public.<>) new.state_name) OR (old.block IS DISTINCT FROM new.block) OR ((old.blocking_factor)::text IS DISTINCT FROM (new.blocking_factor)::text) OR (old.cart_column IS DISTINCT FROM new.cart_column) OR (old.cart_config_id IS DISTINCT FROM new.cart_config_id) OR ((old.comment)::text IS DISTINCT FROM (new.comment)::text) OR (old.dataset_id IS DISTINCT FROM new.dataset_id) OR ((old.eus_proposal_id)::text IS DISTINCT FROM (new.eus_proposal_id)::text) OR ((old.instrument_group)::text IS DISTINCT FROM (new.instrument_group)::text) OR ((old.instrument_setting)::text IS DISTINCT FROM (new.instrument_setting)::text) OR (old.location_id IS DISTINCT FROM new.location_id) OR (old.mrm_attachment IS DISTINCT FROM new.mrm_attachment) OR ((old.note)::text IS DISTINCT FROM (new.note)::text) OR (old.priority IS DISTINCT FROM new.priority) OR (old.queue_date IS DISTINCT FROM new.queue_date) OR (old.queue_instrument_id IS DISTINCT FROM new.queue_instrument_id) OR ((old.request_internal_standard)::text IS DISTINCT FROM (new.request_internal_standard)::text) OR (old.request_run_finish IS DISTINCT FROM new.request_run_finish) OR (old.request_run_start IS DISTINCT FROM new.request_run_start) OR (old.request_type_id IS DISTINCT FROM new.request_type_id) OR (old.run_order IS DISTINCT FROM new.run_order) OR ((old.separation_group)::text IS DISTINCT FROM (new.separation_group)::text) OR ((old.special_instructions)::text IS DISTINCT FROM (new.special_instructions)::text) OR ((old.vialing_conc)::text IS DISTINCT FROM (new.vialing_conc)::text) OR ((old.vialing_vol)::text IS DISTINCT FROM (new.vialing_vol)::text) OR ((old.well)::text IS DISTINCT FROM (new.well)::text) OR ((old.wellplate)::text IS DISTINCT FROM (new.wellplate)::text) OR ((old.work_package)::text IS DISTINCT FROM (new.work_package)::text))) EXECUTE FUNCTION public.trigfn_t_requested_run_after_insert_or_update();

--
-- Name: t_requested_run fk_t_requested_run_t_attachments; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT fk_t_requested_run_t_attachments FOREIGN KEY (mrm_attachment) REFERENCES public.t_attachments(attachment_id);

--
-- Name: t_requested_run fk_t_requested_run_t_charge_code_activation_state; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT fk_t_requested_run_t_charge_code_activation_state FOREIGN KEY (cached_wp_activation_state) REFERENCES public.t_charge_code_activation_state(activation_state);

--
-- Name: t_requested_run fk_t_requested_run_t_dataset; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT fk_t_requested_run_t_dataset FOREIGN KEY (dataset_id) REFERENCES public.t_dataset(dataset_id);

--
-- Name: t_requested_run fk_t_requested_run_t_dataset_type_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT fk_t_requested_run_t_dataset_type_name FOREIGN KEY (request_type_id) REFERENCES public.t_dataset_type_name(dataset_type_id);

--
-- Name: t_requested_run fk_t_requested_run_t_eus_proposals; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT fk_t_requested_run_t_eus_proposals FOREIGN KEY (eus_proposal_id) REFERENCES public.t_eus_proposals(proposal_id);

--
-- Name: t_requested_run fk_t_requested_run_t_eus_usage_type; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT fk_t_requested_run_t_eus_usage_type FOREIGN KEY (eus_usage_type_id) REFERENCES public.t_eus_usage_type(eus_usage_type_id);

--
-- Name: t_requested_run fk_t_requested_run_t_experiments; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT fk_t_requested_run_t_experiments FOREIGN KEY (exp_id) REFERENCES public.t_experiments(exp_id);

--
-- Name: t_requested_run fk_t_requested_run_t_lc_cart; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT fk_t_requested_run_t_lc_cart FOREIGN KEY (cart_id) REFERENCES public.t_lc_cart(cart_id);

--
-- Name: t_requested_run fk_t_requested_run_t_lc_cart_configuration; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT fk_t_requested_run_t_lc_cart_configuration FOREIGN KEY (cart_config_id) REFERENCES public.t_lc_cart_configuration(cart_config_id);

--
-- Name: t_requested_run fk_t_requested_run_t_material_locations; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT fk_t_requested_run_t_material_locations FOREIGN KEY (location_id) REFERENCES public.t_material_locations(location_id);

--
-- Name: t_requested_run fk_t_requested_run_t_requested_run_batches; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT fk_t_requested_run_t_requested_run_batches FOREIGN KEY (batch_id) REFERENCES public.t_requested_run_batches(batch_id);

--
-- Name: t_requested_run fk_t_requested_run_t_requested_run_queue_state; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT fk_t_requested_run_t_requested_run_queue_state FOREIGN KEY (queue_state) REFERENCES public.t_requested_run_queue_state(queue_state);

--
-- Name: t_requested_run fk_t_requested_run_t_requested_run_state_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT fk_t_requested_run_t_requested_run_state_name FOREIGN KEY (state_name) REFERENCES public.t_requested_run_state_name(state_name);

--
-- Name: t_requested_run fk_t_requested_run_t_separation_group; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT fk_t_requested_run_t_separation_group FOREIGN KEY (separation_group) REFERENCES public.t_separation_group(separation_group) ON UPDATE CASCADE;

--
-- Name: t_requested_run fk_t_requested_run_t_service_type; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT fk_t_requested_run_t_service_type FOREIGN KEY (service_type_id) REFERENCES cc.t_service_type(service_type_id) ON UPDATE CASCADE;

--
-- Name: t_requested_run fk_t_requested_run_t_users; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT fk_t_requested_run_t_users FOREIGN KEY (requester_username) REFERENCES public.t_users(username) ON UPDATE CASCADE;

--
-- Name: TABLE t_requested_run; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_requested_run TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_requested_run TO writeaccess;

