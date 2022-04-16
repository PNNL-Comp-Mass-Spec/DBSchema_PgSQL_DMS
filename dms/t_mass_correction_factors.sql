--
-- Name: t_mass_correction_factors; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_mass_correction_factors (
    mass_correction_id integer NOT NULL,
    mass_correction_tag public.citext NOT NULL,
    description public.citext,
    monoisotopic_mass double precision NOT NULL,
    average_mass double precision,
    affected_atom character(1) NOT NULL,
    original_source public.citext NOT NULL,
    original_source_name public.citext NOT NULL,
    alternative_name public.citext,
    empirical_formula public.citext
);


ALTER TABLE public.t_mass_correction_factors OWNER TO d3l243;

--
-- Name: TABLE t_mass_correction_factors; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_mass_correction_factors TO readaccess;

