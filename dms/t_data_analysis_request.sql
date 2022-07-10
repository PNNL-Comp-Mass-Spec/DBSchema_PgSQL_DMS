--
-- Name: t_data_analysis_request; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_data_analysis_request (
    request_id integer NOT NULL,
    request_name public.citext NOT NULL,
    analysis_type public.citext DEFAULT 'Metabolomics'::public.citext NOT NULL,
    requester_prn public.citext,
    description public.citext DEFAULT ''::public.citext NOT NULL,
    analysis_specifications public.citext,
    comment public.citext,
    representative_batch_id integer,
    data_package_id integer,
    exp_group_id integer,
    work_package public.citext,
    requested_personnel public.citext,
    assigned_personnel public.citext DEFAULT ''::public.citext,
    priority public.citext DEFAULT 'Normal'::public.citext,
    reason_for_high_priority public.citext,
    estimated_analysis_time_days integer DEFAULT 1 NOT NULL,
    state smallint DEFAULT 1 NOT NULL,
    state_comment public.citext,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    state_changed timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    closed timestamp without time zone,
    campaign public.citext,
    organism public.citext,
    eus_proposal_id public.citext,
    dataset_count integer
);


ALTER TABLE public.t_data_analysis_request OWNER TO d3l243;

--
-- Name: t_data_analysis_request_request_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_data_analysis_request ALTER COLUMN request_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_data_analysis_request_request_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_data_analysis_request pk_t_data_analysis_request; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_data_analysis_request
    ADD CONSTRAINT pk_t_data_analysis_request PRIMARY KEY (request_id);

--
-- Name: t_data_analysis_request fk_t_data_analysis_request_t_data_analysis_request_type_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_data_analysis_request
    ADD CONSTRAINT fk_t_data_analysis_request_t_data_analysis_request_type_name FOREIGN KEY (analysis_type) REFERENCES public.t_data_analysis_request_type_name(analysis_type);

--
-- Name: t_data_analysis_request fk_t_data_analysis_request_t_experiment_groups; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_data_analysis_request
    ADD CONSTRAINT fk_t_data_analysis_request_t_experiment_groups FOREIGN KEY (exp_group_id) REFERENCES public.t_experiment_groups(group_id);

--
-- Name: t_data_analysis_request fk_t_data_analysis_request_t_requested_run_batches; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_data_analysis_request
    ADD CONSTRAINT fk_t_data_analysis_request_t_requested_run_batches FOREIGN KEY (representative_batch_id) REFERENCES public.t_requested_run_batches(batch_id);

--
-- Name: TABLE t_data_analysis_request; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_data_analysis_request TO readaccess;

