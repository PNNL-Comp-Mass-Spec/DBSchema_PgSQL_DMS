--
-- Name: t_instrument_group; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_group (
    instrument_group public.citext NOT NULL,
    usage public.citext DEFAULT ''::public.citext,
    comment public.citext DEFAULT ''::public.citext,
    active smallint DEFAULT 1 NOT NULL,
    default_dataset_type integer,
    allocation_tag public.citext,
    sample_prep_visible smallint DEFAULT 1 NOT NULL,
    requested_run_visible smallint DEFAULT 1 NOT NULL,
    target_instrument_group public.citext
);


ALTER TABLE public.t_instrument_group OWNER TO d3l243;

--
-- Name: t_instrument_group pk_t_instrument_group; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_group
    ADD CONSTRAINT pk_t_instrument_group PRIMARY KEY (instrument_group);

--
-- Name: TABLE t_instrument_group; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_group TO readaccess;

