--
-- Name: v_mass_correction_factors; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mass_correction_factors AS
 SELECT t_mass_correction_factors.mass_correction_id,
    t_mass_correction_factors.mass_correction_tag,
    t_mass_correction_factors.description,
    t_mass_correction_factors.monoisotopic_mass,
    t_mass_correction_factors.average_mass,
    COALESCE(t_mass_correction_factors.empirical_formula, ''::public.citext) AS empirical_formula,
    t_mass_correction_factors.affected_atom,
    t_mass_correction_factors.original_source,
    t_mass_correction_factors.original_source_name,
    t_mass_correction_factors.alternative_name
   FROM public.t_mass_correction_factors;


ALTER VIEW public.v_mass_correction_factors OWNER TO d3l243;

--
-- Name: TABLE v_mass_correction_factors; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mass_correction_factors TO readaccess;
GRANT SELECT ON TABLE public.v_mass_correction_factors TO writeaccess;

