--
-- Name: t_requested_run_updates; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_requested_run_updates (
    entry_id integer NOT NULL,
    request_id integer NOT NULL,
    work_package_change public.citext,
    eus_proposal_change public.citext,
    eus_usage_type_change text,
    service_type_change text,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE public.t_requested_run_updates OWNER TO d3l243;

--
-- Name: t_requested_run_updates_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_requested_run_updates ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_requested_run_updates_entry_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_requested_run_updates pk_t_requested_run_updates; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run_updates
    ADD CONSTRAINT pk_t_requested_run_updates PRIMARY KEY (entry_id);

ALTER TABLE public.t_requested_run_updates CLUSTER ON pk_t_requested_run_updates;

--
-- Name: ix_t_requested_run_updates_entered; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_updates_entered ON public.t_requested_run_updates USING btree (entered);

--
-- Name: ix_t_requested_run_updates_request_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_updates_request_id ON public.t_requested_run_updates USING btree (request_id);

--
-- Name: TABLE t_requested_run_updates; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_requested_run_updates TO readaccess;
GRANT SELECT,INSERT,UPDATE ON TABLE public.t_requested_run_updates TO writeaccess;

