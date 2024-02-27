--
-- Name: t_deleted_requested_run; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_deleted_requested_run (
    entry_id integer NOT NULL,
    request_id integer NOT NULL,
    request_name public.citext NOT NULL,
    requester_username public.citext NOT NULL,
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
    eus_person_id integer,
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
    entered timestamp without time zone,
    updated timestamp without time zone,
    updated_by public.citext,
    deleted timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    deleted_by public.citext
);


ALTER TABLE public.t_deleted_requested_run OWNER TO d3l243;

--
-- Name: t_deleted_requested_run_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_deleted_requested_run ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_deleted_requested_run_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_deleted_requested_run pk_t_deleted_requested_run; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_deleted_requested_run
    ADD CONSTRAINT pk_t_deleted_requested_run PRIMARY KEY (entry_id);

--
-- Name: ix_t_deleted_requested_run_batch_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_deleted_requested_run_batch_id ON public.t_deleted_requested_run USING btree (batch_id);

--
-- Name: ix_t_deleted_requested_run_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_deleted_requested_run_dataset_id ON public.t_deleted_requested_run USING btree (dataset_id);

--
-- Name: ix_t_deleted_requested_run_exp_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_deleted_requested_run_exp_id ON public.t_deleted_requested_run USING btree (exp_id);

--
-- Name: ix_t_deleted_requested_run_request_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_deleted_requested_run_request_id ON public.t_deleted_requested_run USING btree (request_id);

--
-- Name: t_deleted_requested_run fk_t_deleted_requested_run_t_dataset_type_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_deleted_requested_run
    ADD CONSTRAINT fk_t_deleted_requested_run_t_dataset_type_name FOREIGN KEY (request_type_id) REFERENCES public.t_dataset_type_name(dataset_type_id);

--
-- Name: t_deleted_requested_run fk_t_deleted_requested_run_t_eus_usage_type; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_deleted_requested_run
    ADD CONSTRAINT fk_t_deleted_requested_run_t_eus_usage_type FOREIGN KEY (eus_usage_type_id) REFERENCES public.t_eus_usage_type(eus_usage_type_id);

--
-- Name: t_deleted_requested_run fk_t_deleted_requested_run_t_requested_run_state_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_deleted_requested_run
    ADD CONSTRAINT fk_t_deleted_requested_run_t_requested_run_state_name FOREIGN KEY (state_name) REFERENCES public.t_requested_run_state_name(state_name);

--
-- Name: TABLE t_deleted_requested_run; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_deleted_requested_run TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_deleted_requested_run TO writeaccess;

