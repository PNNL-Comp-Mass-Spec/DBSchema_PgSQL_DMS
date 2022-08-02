--
-- Name: t_analysis_job; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job (
    job integer NOT NULL,
    batch_id integer,
    priority integer DEFAULT 2 NOT NULL,
    created timestamp without time zone NOT NULL,
    start timestamp without time zone,
    finish timestamp without time zone,
    analysis_tool_id integer DEFAULT 0 NOT NULL,
    param_file_name public.citext NOT NULL,
    settings_file_name public.citext NOT NULL,
    organism_db_name public.citext,
    organism_id integer NOT NULL,
    dataset_id integer NOT NULL,
    comment public.citext DEFAULT ''::public.citext,
    owner public.citext,
    job_state_id integer DEFAULT 1 NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    assigned_processor_name public.citext,
    results_folder_name public.citext,
    protein_collection_list public.citext DEFAULT 'na'::public.citext,
    protein_options_list public.citext DEFAULT 'na'::public.citext NOT NULL,
    request_id integer DEFAULT 1 NOT NULL,
    extraction_processor public.citext,
    extraction_start timestamp without time zone,
    extraction_finish timestamp without time zone,
    analysis_manager_error smallint DEFAULT 0 NOT NULL,
    data_extraction_error smallint DEFAULT 0 NOT NULL,
    propagation_mode smallint DEFAULT 0 NOT NULL,
    state_name_cached public.citext DEFAULT ''::public.citext NOT NULL,
    processing_time_minutes real,
    special_processing public.citext,
    dataset_unreviewed smallint DEFAULT 0 NOT NULL,
    purged smallint DEFAULT 0 NOT NULL,
    myemsl_state smallint DEFAULT 0 NOT NULL,
    analysis_tool_cached public.citext DEFAULT ''::public.citext,
    progress real,
    eta_minutes real,
    CONSTRAINT ck_t_analysis_job_propagation_mode CHECK (((propagation_mode = 1) OR (propagation_mode = 0)))
);


ALTER TABLE public.t_analysis_job OWNER TO d3l243;

--
-- Name: t_analysis_job pk_t_analysis_job; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job
    ADD CONSTRAINT pk_t_analysis_job PRIMARY KEY (job);

--
-- Name: ix_t_analysis_job_analysis_tool_cached; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_analysis_tool_cached ON public.t_analysis_job USING btree (analysis_tool_cached);

--
-- Name: ix_t_analysis_job_batch_id_include_job_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_batch_id_include_job_id ON public.t_analysis_job USING btree (batch_id) INCLUDE (job);

--
-- Name: ix_t_analysis_job_created_include_job_state_id_progress; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_created_include_job_state_id_progress ON public.t_analysis_job USING btree (created) INCLUDE (job, job_state_id, progress);

--
-- Name: ix_t_analysis_job_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_dataset_id ON public.t_analysis_job USING btree (dataset_id);

--
-- Name: ix_t_analysis_job_dataset_id_job_id_state_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_dataset_id_job_id_state_id ON public.t_analysis_job USING btree (dataset_id, job, job_state_id);

--
-- Name: ix_t_analysis_job_finish; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_finish ON public.t_analysis_job USING btree (finish);

--
-- Name: ix_t_analysis_job_job_state_id_job; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_job_state_id_job ON public.t_analysis_job USING btree (job_state_id, job);

--
-- Name: ix_t_analysis_job_last_affected; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_last_affected ON public.t_analysis_job USING btree (last_affected);

--
-- Name: ix_t_analysis_job_organism_dbname; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_organism_dbname ON public.t_analysis_job USING btree (organism_db_name);

--
-- Name: ix_t_analysis_job_request_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_request_id ON public.t_analysis_job USING btree (request_id);

--
-- Name: ix_t_analysis_job_started_include_job_state_id_progress; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_started_include_job_state_id_progress ON public.t_analysis_job USING btree (start) INCLUDE (job, job_state_id, progress);

--
-- Name: ix_t_analysis_job_state_id_include_job_priority_tool_dataset; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_state_id_include_job_priority_tool_dataset ON public.t_analysis_job USING btree (job_state_id) INCLUDE (priority, job, dataset_id, analysis_tool_id);

--
-- Name: ix_t_analysis_job_state_name_cached; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_state_name_cached ON public.t_analysis_job USING btree (state_name_cached);

--
-- Name: ix_t_analysis_job_tool_id_include_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_tool_id_include_dataset_id ON public.t_analysis_job USING btree (analysis_tool_id) INCLUDE (dataset_id);

--
-- Name: ix_t_analysis_job_tool_id_include_param_file_created; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_tool_id_include_param_file_created ON public.t_analysis_job USING btree (analysis_tool_id) INCLUDE (param_file_name, created);

--
-- Name: ix_t_analysis_job_tool_id_job_id_dataset_id_include_ajstart; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_tool_id_job_id_dataset_id_include_ajstart ON public.t_analysis_job USING btree (analysis_tool_id, job, dataset_id) INCLUDE (start);

--
-- Name: ix_t_analysis_job_tool_id_state_id_include_job_priority; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_tool_id_state_id_include_job_priority ON public.t_analysis_job USING btree (analysis_tool_id, job_state_id) INCLUDE (job, priority, dataset_id, comment, owner, special_processing);

--
-- Name: t_analysis_job trig_t_analysis_job_after_delete; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_analysis_job_after_delete AFTER DELETE ON public.t_analysis_job REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_analysis_job_after_delete();

--
-- Name: t_analysis_job trig_t_analysis_job_after_update_all; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_analysis_job_after_update_all AFTER UPDATE ON public.t_analysis_job REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_analysis_job_after_update_all();

--
-- Name: t_analysis_job fk_t_analysis_job_t_analysis_job_batches; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job
    ADD CONSTRAINT fk_t_analysis_job_t_analysis_job_batches FOREIGN KEY (batch_id) REFERENCES public.t_analysis_job_batches(batch_id);

--
-- Name: t_analysis_job fk_t_analysis_job_t_analysis_job_request; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job
    ADD CONSTRAINT fk_t_analysis_job_t_analysis_job_request FOREIGN KEY (request_id) REFERENCES public.t_analysis_job_request(request_id);

--
-- Name: t_analysis_job fk_t_analysis_job_t_analysis_job_state; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job
    ADD CONSTRAINT fk_t_analysis_job_t_analysis_job_state FOREIGN KEY (job_state_id) REFERENCES public.t_analysis_job_state(job_state_id);

--
-- Name: t_analysis_job fk_t_analysis_job_t_analysis_tool; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job
    ADD CONSTRAINT fk_t_analysis_job_t_analysis_tool FOREIGN KEY (analysis_tool_id) REFERENCES public.t_analysis_tool(analysis_tool_id);

--
-- Name: t_analysis_job fk_t_analysis_job_t_dataset; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job
    ADD CONSTRAINT fk_t_analysis_job_t_dataset FOREIGN KEY (dataset_id) REFERENCES public.t_dataset(dataset_id);

--
-- Name: t_analysis_job fk_t_analysis_job_t_myemsl_state; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job
    ADD CONSTRAINT fk_t_analysis_job_t_myemsl_state FOREIGN KEY (myemsl_state) REFERENCES public.t_myemsl_state(myemsl_state);

--
-- Name: t_analysis_job fk_t_analysis_job_t_organisms; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job
    ADD CONSTRAINT fk_t_analysis_job_t_organisms FOREIGN KEY (organism_id) REFERENCES public.t_organisms(organism_id);

--
-- Name: t_analysis_job fk_t_analysis_job_t_param_files; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job
    ADD CONSTRAINT fk_t_analysis_job_t_param_files FOREIGN KEY (param_file_name) REFERENCES public.t_param_files(param_file_name) ON UPDATE CASCADE;

--
-- Name: t_analysis_job fk_t_analysis_job_t_yes_no; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job
    ADD CONSTRAINT fk_t_analysis_job_t_yes_no FOREIGN KEY (dataset_unreviewed) REFERENCES public.t_yes_no(flag);

--
-- Name: TABLE t_analysis_job; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job TO readaccess;

