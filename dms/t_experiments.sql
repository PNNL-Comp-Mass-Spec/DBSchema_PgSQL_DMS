--
-- Name: t_experiments; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_experiments (
    exp_id integer NOT NULL,
    experiment public.citext NOT NULL,
    researcher_username public.citext,
    organism_id integer NOT NULL,
    reason public.citext,
    comment public.citext,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    sample_concentration public.citext,
    lab_notebook_ref public.citext,
    campaign_id integer NOT NULL,
    biomaterial_list public.citext,
    labelling public.citext NOT NULL,
    container_id integer DEFAULT 1 NOT NULL,
    material_active public.citext DEFAULT 'Active'::public.citext NOT NULL,
    enzyme_id integer DEFAULT 10 NOT NULL,
    sample_prep_request_id integer DEFAULT 0 NOT NULL,
    internal_standard_id integer DEFAULT 0 NOT NULL,
    post_digest_internal_std_id integer DEFAULT 0 NOT NULL,
    wellplate public.citext,
    well public.citext,
    alkylation public.citext DEFAULT 'N'::bpchar NOT NULL,
    barcode public.citext,
    tissue_id public.citext,
    tissue_source_id smallint,
    disease_id public.citext,
    last_used date DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_t_experiment_exp_name_not_empty CHECK ((COALESCE(experiment, ''::public.citext) OPERATOR(public.<>) ''::public.citext)),
    CONSTRAINT ck_t_experiments_experiment_name_whitespace CHECK ((public.has_whitespace_chars((experiment)::text, false) = false))
);


ALTER TABLE public.t_experiments OWNER TO d3l243;

--
-- Name: TABLE t_experiments; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON TABLE public.t_experiments IS '
For fast lookups on experiment name, utilize index
ix_t_experiments_experiment_lower_text_pattern_ops,
with queries of the form:

SELECT *
FROM t_experiments
WHERE Lower(experiment::text) LIKE Lower(''DS%Leaf%'');

Query performance comparisons:

-- Query 1: no filter
EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT TEXT)
SELECT *
FROM t_experiments
ORDER BY exp_id DESC
LIMIT 125;

Limit (cost=0.42..11.43 rows=125 width=290)
      (actual time=0.050..0.214 rows=125 loops=1)
  ->  Index Scan Backward using pk_t_experiments
      (cost=0.42..32534.47 rows=369300 width=290)
      (actual time=0.048..0.188 rows=125 loops=1)
Planning Time: 0.277 ms
Execution Time: 0.290 ms

-- Query 2: filter on request name
EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT TEXT)
SELECT *
FROM t_experiments
WHERE experiment SIMILAR TO ''DS%Leaf%''
ORDER BY exp_id DESC
LIMIT 125;

Limit (cost=0.42..2265.95 rows=125 width=290)
      (actual time=49.371..150.310 rows=96 loops=1)
  ->  Index Scan Backward using pk_t_experiments
      (cost=0.42..33457.72 rows=1846 width=290)
      (actual time=49.367..150.296 rows=96 loops=1)
        Filter: (t_experiments.experiment ~ ''^(?:DS.*Leaf.*)$''::text)
        Rows Removed by Filter: 369204
Planning Time: 0.366 ms
Execution Time: 150.404 ms

-- Query 3: when filtering, cast to text and use lower()
EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT TEXT)
SELECT *
FROM t_experiments
WHERE Lower(experiment::text) SIMILAR TO Lower(''DS%Leaf%'')
ORDER BY exp_id DESC
LIMIT 125;

Limit (cost=1968.82..1968.91 rows=37 width=290)
      (actual time=2.946..2.972 rows=96 loops=1)
  ->  Sort (cost=1968.82..1968.91 rows=37 width=290)
           (actual time=2.944..2.955 rows=96 loops=1)
        Sort Key: t_experiments.exp_id DESC
        Sort Method: quicksort  Memory: 73kB
        ->  Bitmap Heap Scan on public.t_experiments
            (cost=29.89..1967.85 rows=37 width=290)
            (actual time=1.842..2.883 rows=96 loops=1)
              Filter: (lower((t_experiments.experiment)::text) ~ ''^(?:ds.*leaf.*)$''::text)
              Rows Removed by Filter: 1022
              ->  Bitmap Index Scan on ix_t_experiments_experiment_lower_text_pattern_ops
                  (cost=0.00..29.88 rows=1846 width=0)
                  (actual time=0.216..0.217 rows=1118 loops=1)
                    Index Cond: ((lower((t_experiments.experiment)::text) ~>=~ ''ds''::text) AND
                                 (lower((t_experiments.experiment)::text) ~<~ ''dt''::text))
Planning Time: 0.466 ms
Execution Time: 3.080 ms

-- Query 4: use LIKE instead of SIMILAR TO
EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT TEXT)
SELECT *
FROM t_experiments
WHERE Lower(experiment::text) LIKE Lower(''DS%Leaf%'')
ORDER BY exp_id DESC
LIMIT 125;

Limit (cost=1968.82..1968.91 rows=37 width=290)
      (actual time=1.821..1.852 rows=96 loops=1)
  ->  Sort (cost=1968.82..1968.91 rows=37 width=290)
           (actual time=1.819..1.832 rows=96 loops=1)
        Sort Key: t_experiments.exp_id DESC
        Sort Method: quicksort  Memory: 73kB
        ->  Bitmap Heap Scan on public.t_experiments
            (cost=29.89..1967.85 rows=37 width=290)
            (actual time=1.165..1.756 rows=96 loops=1)
              Filter: (lower((t_experiments.experiment)::text) ~~ ''ds%leaf%''::text)
              Rows Removed by Filter: 1022
              ->  Bitmap Index Scan on ix_t_experiments_experiment_lower_text_pattern_ops
                  (cost=0.00..29.88 rows=1846 width=0)
                  (actual time=0.227..0.227 rows=1118 loops=1)
                    Index Cond: ((lower((t_experiments.experiment)::text) ~>=~ ''ds''::text) AND
                                 (lower((t_experiments.experiment)::text) ~<~ ''dt''::text))
Planning Time: 0.380 ms
Execution Time: 1.948 ms
';

--
-- Name: t_experiments_exp_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_experiments ALTER COLUMN exp_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_experiments_exp_id_seq
    START WITH 5000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_experiments pk_t_experiments; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiments
    ADD CONSTRAINT pk_t_experiments PRIMARY KEY (exp_id);

--
-- Name: ix_t_experiments_campaign_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_experiments_campaign_id ON public.t_experiments USING btree (campaign_id);

--
-- Name: ix_t_experiments_campaign_id_exp_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_experiments_campaign_id_exp_id ON public.t_experiments USING btree (campaign_id, exp_id);

--
-- Name: ix_t_experiments_container_id_include_campaign_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_experiments_container_id_include_campaign_id ON public.t_experiments USING btree (container_id) INCLUDE (campaign_id);

--
-- Name: ix_t_experiments_created; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_experiments_created ON public.t_experiments USING btree (created);

--
-- Name: ix_t_experiments_exp_id_campaign_id_experiment; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_experiments_exp_id_campaign_id_experiment ON public.t_experiments USING btree (exp_id, campaign_id, experiment);

--
-- Name: ix_t_experiments_exp_id_container_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_experiments_exp_id_container_id ON public.t_experiments USING btree (exp_id, container_id);

--
-- Name: ix_t_experiments_exp_id_ex_campaign_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_experiments_exp_id_ex_campaign_id ON public.t_experiments USING btree (exp_id, campaign_id);

--
-- Name: ix_t_experiments_experiment_lower_text_pattern_ops; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_experiments_experiment_lower_text_pattern_ops ON public.t_experiments USING btree (lower((experiment)::text) text_pattern_ops);

--
-- Name: ix_t_experiments_experiment_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_experiments_experiment_name ON public.t_experiments USING btree (experiment);

--
-- Name: ix_t_experiments_experiment_name_container_id_exp_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_experiments_experiment_name_container_id_exp_id ON public.t_experiments USING btree (experiment, container_id, exp_id);

--
-- Name: ix_t_experiments_prep_request_id_include_ex_created; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_experiments_prep_request_id_include_ex_created ON public.t_experiments USING btree (sample_prep_request_id) INCLUDE (created);

--
-- Name: ix_t_experiments_tissue_id_include_experiment_name_organism_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_experiments_tissue_id_include_experiment_name_organism_id ON public.t_experiments USING btree (tissue_id) INCLUDE (experiment, organism_id);

--
-- Name: ix_t_experiments_wellplate_well_experiment; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_experiments_wellplate_well_experiment ON public.t_experiments USING btree (wellplate, well, experiment);

--
-- Name: t_experiments trig_t_experiments_after_delete_all; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_experiments_after_delete_all AFTER DELETE ON public.t_experiments REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_experiments_after_delete_all();

--
-- Name: t_experiments trig_t_experiments_after_delete_row; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_experiments_after_delete_row AFTER DELETE ON public.t_experiments REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_experiments_after_delete();

--
-- Name: t_experiments trig_t_experiments_after_insert; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_experiments_after_insert AFTER INSERT ON public.t_experiments REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_experiments_after_insert();

--
-- Name: t_experiments trig_t_experiments_after_update_all; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_experiments_after_update_all AFTER UPDATE ON public.t_experiments REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_experiments_after_update_all();

--
-- Name: t_experiments trig_t_experiments_after_update_row; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_experiments_after_update_row AFTER UPDATE ON public.t_experiments FOR EACH ROW WHEN ((old.experiment OPERATOR(public.<>) new.experiment)) EXECUTE FUNCTION public.trigfn_t_experiments_after_update();

--
-- Name: t_experiments fk_t_experiments_t_campaign; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiments
    ADD CONSTRAINT fk_t_experiments_t_campaign FOREIGN KEY (campaign_id) REFERENCES public.t_campaign(campaign_id);

--
-- Name: t_experiments fk_t_experiments_t_enzymes; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiments
    ADD CONSTRAINT fk_t_experiments_t_enzymes FOREIGN KEY (enzyme_id) REFERENCES public.t_enzymes(enzyme_id);

--
-- Name: t_experiments fk_t_experiments_t_internal_standards; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiments
    ADD CONSTRAINT fk_t_experiments_t_internal_standards FOREIGN KEY (internal_standard_id) REFERENCES public.t_internal_standards(internal_standard_id);

--
-- Name: t_experiments fk_t_experiments_t_internal_standards1; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiments
    ADD CONSTRAINT fk_t_experiments_t_internal_standards1 FOREIGN KEY (post_digest_internal_std_id) REFERENCES public.t_internal_standards(internal_standard_id);

--
-- Name: t_experiments fk_t_experiments_t_material_containers; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiments
    ADD CONSTRAINT fk_t_experiments_t_material_containers FOREIGN KEY (container_id) REFERENCES public.t_material_containers(container_id);

--
-- Name: t_experiments fk_t_experiments_t_organisms; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiments
    ADD CONSTRAINT fk_t_experiments_t_organisms FOREIGN KEY (organism_id) REFERENCES public.t_organisms(organism_id);

--
-- Name: t_experiments fk_t_experiments_t_sample_labelling; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiments
    ADD CONSTRAINT fk_t_experiments_t_sample_labelling FOREIGN KEY (labelling) REFERENCES public.t_sample_labelling(label);

--
-- Name: t_experiments fk_t_experiments_t_sample_prep_request; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiments
    ADD CONSTRAINT fk_t_experiments_t_sample_prep_request FOREIGN KEY (sample_prep_request_id) REFERENCES public.t_sample_prep_request(prep_request_id);

--
-- Name: t_experiments fk_t_experiments_t_tissue_source; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiments
    ADD CONSTRAINT fk_t_experiments_t_tissue_source FOREIGN KEY (tissue_source_id) REFERENCES public.t_tissue_source(tissue_source_id);

--
-- Name: t_experiments fk_t_experiments_t_users; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiments
    ADD CONSTRAINT fk_t_experiments_t_users FOREIGN KEY (researcher_username) REFERENCES public.t_users(username) ON UPDATE CASCADE;

--
-- Name: TABLE t_experiments; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_experiments TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_experiments TO writeaccess;

