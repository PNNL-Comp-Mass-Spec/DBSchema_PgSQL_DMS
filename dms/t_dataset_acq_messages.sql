--
-- Name: t_dataset_acq_messages; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_acq_messages (
    entry_id integer NOT NULL,
    dataset_id integer NOT NULL,
    msg_type public.citext NOT NULL,
    message public.citext NOT NULL,
    obs_count integer,
    elution_time_min numeric,
    elution_time_max numeric,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_dataset_acq_messages OWNER TO d3l243;

--
-- Name: t_dataset_acq_messages_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_dataset_acq_messages ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_dataset_acq_messages_entry_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_dataset_acq_messages pk_t_dataset_acq_messages; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_acq_messages
    ADD CONSTRAINT pk_t_dataset_acq_messages PRIMARY KEY (dataset_id, msg_type, message);

--
-- Name: ix_t_dataset_acq_messages_message; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_acq_messages_message ON public.t_dataset_acq_messages USING btree (message);

--
-- Name: TABLE t_dataset_acq_messages; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_acq_messages TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_dataset_acq_messages TO writeaccess;

