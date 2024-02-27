--
-- Name: t_requested_run_batches; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_requested_run_batches (
    batch_id integer NOT NULL,
    batch public.citext NOT NULL,
    description public.citext,
    owner_user_id integer,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    locked public.citext DEFAULT 'Yes'::public.citext NOT NULL,
    last_ordered timestamp without time zone,
    requested_batch_priority public.citext DEFAULT 'Normal'::public.citext NOT NULL,
    actual_batch_priority public.citext DEFAULT 'Normal'::public.citext NOT NULL,
    requested_completion_date timestamp without time zone,
    justification_for_high_priority public.citext,
    comment public.citext,
    batch_group_id integer,
    batch_group_order integer,
    rfid_hex_id public.citext GENERATED ALWAYS AS ("left"((encode(((batch_id)::text)::bytea, 'hex'::text) || '000000000000000000000000'::text), 24)) STORED
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
-- Name: ix_t_requested_run_batches_batch_group_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_batches_batch_group_id ON public.t_requested_run_batches USING btree (batch_group_id);

--
-- Name: t_requested_run_batches trig_t_requested_run_batches_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_requested_run_batches_after_update AFTER UPDATE ON public.t_requested_run_batches FOR EACH ROW WHEN (((old.batch OPERATOR(public.<>) new.batch) OR (old.created <> new.created) OR (old.batch_group_id IS DISTINCT FROM new.batch_group_id))) EXECUTE FUNCTION public.trigfn_t_requested_run_batches_after_update();

--
-- Name: t_requested_run_batches fk_t_requested_run_batches_t_requested_run_batch_group; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run_batches
    ADD CONSTRAINT fk_t_requested_run_batches_t_requested_run_batch_group FOREIGN KEY (batch_group_id) REFERENCES public.t_requested_run_batch_group(batch_group_id);

--
-- Name: t_requested_run_batches fk_t_requested_run_batches_t_users; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run_batches
    ADD CONSTRAINT fk_t_requested_run_batches_t_users FOREIGN KEY (owner_user_id) REFERENCES public.t_users(user_id);

--
-- Name: TABLE t_requested_run_batches; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_requested_run_batches TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_requested_run_batches TO writeaccess;

