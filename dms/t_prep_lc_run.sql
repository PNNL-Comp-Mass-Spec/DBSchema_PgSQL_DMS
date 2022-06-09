--
-- Name: t_prep_lc_run; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_prep_lc_run (
    prep_run_id integer NOT NULL,
    tab public.citext,
    instrument public.citext NOT NULL,
    type public.citext,
    lc_column public.citext,
    lc_column_2 public.citext,
    comment public.citext,
    guard_column public.citext DEFAULT 'No'::public.citext NOT NULL,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    operator_prn public.citext,
    digestion_method public.citext,
    sample_type public.citext,
    sample_prep_request public.citext,
    number_of_runs integer,
    instrument_pressure public.citext,
    storage_path integer,
    uploaded timestamp without time zone,
    quality_control public.citext
);


ALTER TABLE public.t_prep_lc_run OWNER TO d3l243;

--
-- Name: t_prep_lc_run_prep_run_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_prep_lc_run ALTER COLUMN prep_run_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_prep_lc_run_prep_run_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_prep_lc_run pk_t_prep_lc_run; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_prep_lc_run
    ADD CONSTRAINT pk_t_prep_lc_run PRIMARY KEY (prep_run_id);

--
-- Name: t_prep_lc_run fk_t_prep_lc_run_t_instrument_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_prep_lc_run
    ADD CONSTRAINT fk_t_prep_lc_run_t_instrument_name FOREIGN KEY (instrument) REFERENCES public.t_instrument_name(instrument);

--
-- Name: TABLE t_prep_lc_run; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_prep_lc_run TO readaccess;

