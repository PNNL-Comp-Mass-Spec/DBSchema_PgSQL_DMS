--
-- Name: t_dataset_create_queue; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_create_queue (
    entry_id integer NOT NULL,
    state_id integer DEFAULT 1 NOT NULL,
    dataset public.citext NOT NULL,
    experiment public.citext NOT NULL,
    instrument public.citext NOT NULL,
    separation_type public.citext,
    lc_cart public.citext,
    lc_cart_config public.citext,
    lc_column public.citext,
    wellplate public.citext,
    well public.citext,
    dataset_type public.citext,
    operator_username public.citext,
    ds_creator_username public.citext,
    comment public.citext,
    interest_rating public.citext,
    request integer,
    work_package public.citext DEFAULT ''::public.citext,
    eus_usage_type public.citext DEFAULT ''::public.citext,
    eus_proposal_id public.citext DEFAULT ''::public.citext,
    eus_users public.citext DEFAULT ''::public.citext,
    capture_share_name public.citext,
    capture_subdirectory public.citext,
    command public.citext DEFAULT 'add'::public.citext NOT NULL,
    processor public.citext,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    start timestamp without time zone,
    finish timestamp without time zone,
    completion_code integer,
    completion_message public.citext
);


ALTER TABLE public.t_dataset_create_queue OWNER TO d3l243;

--
-- Name: t_dataset_create_queue_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_dataset_create_queue ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_dataset_create_queue_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_dataset_create_queue pk_dataset_create_queue; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_create_queue
    ADD CONSTRAINT pk_dataset_create_queue PRIMARY KEY (entry_id);

--
-- Name: ix_t_dataset_create_queue_dataset; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_create_queue_dataset ON public.t_dataset_create_queue USING btree (dataset);

--
-- Name: ix_t_dataset_create_queue_instrument; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_create_queue_instrument ON public.t_dataset_create_queue USING btree (instrument);

--
-- Name: t_dataset_create_queue fk_t_dataset_create_queue_t_dataset_create_queue_state; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_create_queue
    ADD CONSTRAINT fk_t_dataset_create_queue_t_dataset_create_queue_state FOREIGN KEY (state_id) REFERENCES public.t_dataset_create_queue_state(queue_state_id);

--
-- Name: TABLE t_dataset_create_queue; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_create_queue TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_dataset_create_queue TO writeaccess;

