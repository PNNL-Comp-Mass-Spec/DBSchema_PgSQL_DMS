--
-- Name: t_instrument_config_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_config_history (
    entry_id integer NOT NULL,
    instrument public.citext NOT NULL,
    date_of_change timestamp without time zone,
    description public.citext,
    note public.citext,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entered_by public.citext NOT NULL
);


ALTER TABLE public.t_instrument_config_history OWNER TO d3l243;

--
-- Name: t_instrument_config_history_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_instrument_config_history ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_instrument_config_history_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_instrument_config_history pk_t_instrument_config_history; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_config_history
    ADD CONSTRAINT pk_t_instrument_config_history PRIMARY KEY (entry_id);

ALTER TABLE public.t_instrument_config_history CLUSTER ON pk_t_instrument_config_history;

--
-- Name: ix_t_instrument_config_history_instrument_entered; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_instrument_config_history_instrument_entered ON public.t_instrument_config_history USING btree (instrument, entered);

--
-- Name: TABLE t_instrument_config_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_config_history TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_instrument_config_history TO writeaccess;

