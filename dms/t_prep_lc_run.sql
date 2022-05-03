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
    guard_column public.citext NOT NULL,
    created timestamp without time zone NOT NULL,
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
-- Name: t_prep_lc_run pk_t_prep_lc_run; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_prep_lc_run
    ADD CONSTRAINT pk_t_prep_lc_run PRIMARY KEY (prep_run_id);

--
-- Name: TABLE t_prep_lc_run; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_prep_lc_run TO readaccess;

