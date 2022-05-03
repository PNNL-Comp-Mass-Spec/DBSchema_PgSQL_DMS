--
-- Name: t_experiments; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_experiments (
    exp_id integer NOT NULL,
    experiment public.citext NOT NULL,
    researcher_prn public.citext,
    organism_id integer NOT NULL,
    reason public.citext,
    comment public.citext,
    created timestamp without time zone NOT NULL,
    sample_concentration public.citext,
    lab_notebook_ref public.citext,
    campaign_id integer NOT NULL,
    biomaterial_list public.citext,
    labelling public.citext NOT NULL,
    container_id integer DEFAULT 1 NOT NULL,
    material_active public.citext DEFAULT 'Active'::public.citext NOT NULL,
    enzyme_id integer DEFAULT 10 NOT NULL,
    sample_prep_request_id integer DEFAULT 0 NOT NULL,
    internal_standard_id integer DEFAULT 0 NOT NULL,
    post_digest_internal_std_id integer DEFAULT 0 NOT NULL,
    wellplate public.citext,
    well public.citext,
    alkylation character(1) DEFAULT 'N'::bpchar NOT NULL,
    barcode public.citext,
    tissue_id public.citext,
    tissue_source_id smallint,
    disease_id public.citext,
    last_used date DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_t_experiment_exp_name_not_empty CHECK ((COALESCE(experiment, ''::public.citext) OPERATOR(public.<>) ''::public.citext)),
    CONSTRAINT ck_t_experiments_experiment_name_white_space CHECK ((public.has_whitespace_chars((experiment)::text, 0) = false))
);


ALTER TABLE public.t_experiments OWNER TO d3l243;

--
-- Name: t_experiments_exp_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_experiments ALTER COLUMN exp_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_experiments_exp_id_seq
    START WITH 5000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_experiments pk_t_experiments; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiments
    ADD CONSTRAINT pk_t_experiments PRIMARY KEY (exp_id);

--
-- Name: TABLE t_experiments; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_experiments TO readaccess;

