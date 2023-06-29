--
-- Name: t_dataset_qc_instruments; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_qc_instruments (
    instrument public.citext NOT NULL,
    instrument_id integer NOT NULL,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_dataset_qc_instruments OWNER TO d3l243;

--
-- Name: t_dataset_qc_instruments pk_t_dataset_qc_instruments; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_qc_instruments
    ADD CONSTRAINT pk_t_dataset_qc_instruments PRIMARY KEY (instrument);

--
-- Name: TABLE t_dataset_qc_instruments; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_qc_instruments TO readaccess;
GRANT SELECT ON TABLE public.t_dataset_qc_instruments TO writeaccess;

