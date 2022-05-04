--
-- Name: t_mass_correction_factors; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_mass_correction_factors (
    mass_correction_id integer NOT NULL,
    mass_correction_tag public.citext NOT NULL,
    description public.citext,
    monoisotopic_mass double precision NOT NULL,
    average_mass double precision,
    affected_atom character(1) DEFAULT '-'::bpchar NOT NULL,
    original_source public.citext DEFAULT ''::public.citext NOT NULL,
    original_source_name public.citext DEFAULT ''::public.citext NOT NULL,
    alternative_name public.citext,
    empirical_formula public.citext
);


ALTER TABLE public.t_mass_correction_factors OWNER TO d3l243;

--
-- Name: t_mass_correction_factors ix_t_mass_correction_factors_unique_mass_and_affected_atom; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_mass_correction_factors
    ADD CONSTRAINT ix_t_mass_correction_factors_unique_mass_and_affected_atom UNIQUE (monoisotopic_mass, affected_atom);

--
-- Name: t_mass_correction_factors pk_t_mass_correction_factors; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_mass_correction_factors
    ADD CONSTRAINT pk_t_mass_correction_factors PRIMARY KEY (mass_correction_id);

--
-- Name: ix_t_mass_correction_factors_mass_correction_tag; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_mass_correction_factors_mass_correction_tag ON public.t_mass_correction_factors USING btree (mass_correction_tag);

--
-- Name: TABLE t_mass_correction_factors; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_mass_correction_factors TO readaccess;

