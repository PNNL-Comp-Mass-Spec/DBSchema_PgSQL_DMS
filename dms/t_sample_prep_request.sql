--
-- Name: t_sample_prep_request; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_sample_prep_request (
    prep_request_id integer NOT NULL,
    request_type public.citext DEFAULT 'Default'::public.citext NOT NULL,
    request_name public.citext,
    requester_username public.citext,
    reason public.citext,
    organism public.citext,
    tissue_id public.citext,
    biohazard_level public.citext,
    campaign public.citext,
    number_of_samples integer,
    sample_name_list public.citext,
    sample_type public.citext,
    prep_method public.citext,
    prep_by_robot public.citext,
    special_instructions public.citext,
    sample_naming_convention public.citext,
    assigned_personnel public.citext DEFAULT ''::public.citext NOT NULL,
    work_package public.citext,
    user_proposal public.citext,
    instrument_group public.citext,
    instrument_name public.citext,
    dataset_type public.citext DEFAULT 'Normal'::public.citext,
    instrument_analysis_specifications public.citext,
    comment public.citext,
    priority public.citext DEFAULT 'Normal'::public.citext,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    state_id smallint DEFAULT 1 NOT NULL,
    state_comment public.citext,
    requested_personnel public.citext,
    state_changed timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    internal_standard_id integer DEFAULT 0 NOT NULL,
    post_digest_internal_std_id integer DEFAULT 0 NOT NULL,
    estimated_completion timestamp without time zone,
    estimated_prep_time_days integer DEFAULT 1 NOT NULL,
    estimated_ms_runs public.citext,
    eus_usage_type public.citext,
    eus_proposal_id public.citext,
    eus_user_id integer,
    project_number public.citext,
    facility public.citext DEFAULT 'EMSL'::public.citext NOT NULL,
    separation_type public.citext,
    block_and_randomize_samples character(3),
    block_and_randomize_runs character(3),
    reason_for_high_priority public.citext,
    sample_submission_item_count integer,
    biomaterial_item_count integer,
    experiment_item_count integer,
    experiment_group_item_count integer,
    material_containers_item_count integer,
    requested_run_item_count integer,
    dataset_item_count integer,
    hplc_runs_item_count integer,
    total_item_count integer,
    material_container_list public.citext,
    assigned_personnel_sort_key public.citext GENERATED ALWAYS AS (
CASE
    WHEN (assigned_personnel OPERATOR(public.=) 'na'::public.citext) THEN 'zz_na'::text
    ELSE "left"((assigned_personnel)::text, 64)
END) STORED,
    biomaterial_list public.citext,
    number_of_biomaterial_reps_received public.citext,
    replicates_of_samples public.citext,
    CONSTRAINT ck_t_sample_prep_request_request_name_whitespace CHECK ((public.has_whitespace_chars((request_name)::text, true) = false))
);


ALTER TABLE public.t_sample_prep_request OWNER TO d3l243;

--
-- Name: t_sample_prep_request_prep_request_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_sample_prep_request ALTER COLUMN prep_request_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_sample_prep_request_prep_request_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_sample_prep_request pk_t_sample_prep_request; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_prep_request
    ADD CONSTRAINT pk_t_sample_prep_request PRIMARY KEY (prep_request_id);

--
-- Name: ix_t_sample_prep_request; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_sample_prep_request ON public.t_sample_prep_request USING btree (request_name);

--
-- Name: ix_t_sample_prep_request_campaign_include_created; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_sample_prep_request_campaign_include_created ON public.t_sample_prep_request USING btree (campaign) INCLUDE (created);

--
-- Name: ix_t_sample_prep_request_eus_user_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_sample_prep_request_eus_user_id ON public.t_sample_prep_request USING btree (eus_user_id);

--
-- Name: t_sample_prep_request trig_t_sample_prep_request_after_delete; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_sample_prep_request_after_delete AFTER DELETE ON public.t_sample_prep_request REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_sample_prep_request_after_delete();

--
-- Name: t_sample_prep_request trig_t_sample_prep_request_after_insert; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_sample_prep_request_after_insert AFTER INSERT ON public.t_sample_prep_request REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_sample_prep_request_after_insert();

--
-- Name: t_sample_prep_request trig_t_sample_prep_request_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_sample_prep_request_after_update AFTER UPDATE ON public.t_sample_prep_request FOR EACH ROW EXECUTE FUNCTION public.trigfn_t_sample_prep_request_after_update();

--
-- Name: t_sample_prep_request fk_t_sample_prep_request_t_eus_proposals; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_prep_request
    ADD CONSTRAINT fk_t_sample_prep_request_t_eus_proposals FOREIGN KEY (eus_proposal_id) REFERENCES public.t_eus_proposals(proposal_id);

--
-- Name: t_sample_prep_request fk_t_sample_prep_request_t_eus_usage_type; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_prep_request
    ADD CONSTRAINT fk_t_sample_prep_request_t_eus_usage_type FOREIGN KEY (eus_usage_type) REFERENCES public.t_eus_usage_type(eus_usage_type) ON UPDATE CASCADE;

--
-- Name: t_sample_prep_request fk_t_sample_prep_request_t_eus_users; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_prep_request
    ADD CONSTRAINT fk_t_sample_prep_request_t_eus_users FOREIGN KEY (eus_user_id) REFERENCES public.t_eus_users(person_id);

--
-- Name: t_sample_prep_request fk_t_sample_prep_request_t_internal_standards; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_prep_request
    ADD CONSTRAINT fk_t_sample_prep_request_t_internal_standards FOREIGN KEY (internal_standard_id) REFERENCES public.t_internal_standards(internal_standard_id);

--
-- Name: t_sample_prep_request fk_t_sample_prep_request_t_internal_standards1; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_prep_request
    ADD CONSTRAINT fk_t_sample_prep_request_t_internal_standards1 FOREIGN KEY (post_digest_internal_std_id) REFERENCES public.t_internal_standards(internal_standard_id);

--
-- Name: t_sample_prep_request fk_t_sample_prep_request_t_sample_prep_request_state_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_prep_request
    ADD CONSTRAINT fk_t_sample_prep_request_t_sample_prep_request_state_name FOREIGN KEY (state_id) REFERENCES public.t_sample_prep_request_state_name(state_id);

--
-- Name: t_sample_prep_request fk_t_sample_prep_request_t_sample_prep_request_type_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_prep_request
    ADD CONSTRAINT fk_t_sample_prep_request_t_sample_prep_request_type_name FOREIGN KEY (request_type) REFERENCES public.t_sample_prep_request_type_name(request_type);

--
-- Name: TABLE t_sample_prep_request; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_sample_prep_request TO readaccess;
GRANT SELECT ON TABLE public.t_sample_prep_request TO writeaccess;

