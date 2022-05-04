--
-- Name: t_requested_run_batches; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_requested_run_batches (
    batch_id integer NOT NULL,
    batch public.citext NOT NULL,
    description public.citext,
    owner integer,
    created timestamp without time zone NOT NULL,
    locked public.citext DEFAULT 'Yes'::public.citext NOT NULL,
    last_ordered timestamp without time zone,
    requested_batch_priority public.citext DEFAULT 'Normal'::public.citext NOT NULL,
    actual_batch_priority public.citext DEFAULT 'Normal'::public.citext NOT NULL,
    requested_completion_date timestamp without time zone,
    justification_for_high_priority public.citext,
    comment public.citext,
    requested_instrument public.citext DEFAULT 'na'::public.citext NOT NULL,
    hex_id public.citext GENERATED ALWAYS AS ("left"((encode(((batch_id)::text)::bytea, 'hex'::text) || '000000000000000000000000'::text), 24)) STORED
);


ALTER TABLE public.t_requested_run_batches OWNER TO d3l243;

--
-- Name: t_requested_run_batches_batch_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_requested_run_batches ALTER COLUMN batch_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_requested_run_batches_batch_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_requested_run_batches pk_t_requested_run_batches; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run_batches
    ADD CONSTRAINT pk_t_requested_run_batches PRIMARY KEY (batch_id);

--
-- Name: ix_t_requested_run_batches; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_requested_run_batches ON public.t_requested_run_batches USING btree (batch);

--
-- Name: TABLE t_requested_run_batches; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_requested_run_batches TO readaccess;

