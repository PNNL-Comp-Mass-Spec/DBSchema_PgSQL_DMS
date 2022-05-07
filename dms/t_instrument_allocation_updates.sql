--
-- Name: t_instrument_allocation_updates; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_allocation_updates (
    entry_id integer NOT NULL,
    allocation_tag public.citext NOT NULL,
    proposal_id public.citext NOT NULL,
    fiscal_year integer,
    allocated_hours_old double precision,
    allocated_hours_new double precision,
    comment public.citext DEFAULT ''::public.citext,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE public.t_instrument_allocation_updates OWNER TO d3l243;

--
-- Name: t_instrument_allocation_updates_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_instrument_allocation_updates ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_instrument_allocation_updates_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_instrument_allocation_updates pk_t_instrument_allocation_updates; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_allocation_updates
    ADD CONSTRAINT pk_t_instrument_allocation_updates PRIMARY KEY (entry_id);

--
-- Name: ix_t_instrument_allocation_updates_entered; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_instrument_allocation_updates_entered ON public.t_instrument_allocation_updates USING btree (entered);

--
-- Name: ix_t_instrument_allocation_updates_proposal_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_instrument_allocation_updates_proposal_id ON public.t_instrument_allocation_updates USING btree (proposal_id);

--
-- Name: TABLE t_instrument_allocation_updates; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_allocation_updates TO readaccess;

