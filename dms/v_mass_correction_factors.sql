--
-- Name: v_mass_correction_factors; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mass_correction_factors AS
 SELECT mass_correction_id,
    mass_correction_tag,
    description,
    monoisotopic_mass,
    average_mass,
    COALESCE(empirical_formula, ''::public.citext) AS empirical_formula,
    affected_atom,
    original_source,
    original_source_name,
    alternative_name
   FROM public.t_mass_correction_factors;


ALTER VIEW public.v_mass_correction_factors OWNER TO d3l243;

--
-- Name: TABLE v_mass_correction_factors; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mass_correction_factors TO readaccess;
GRANT SELECT ON TABLE public.v_mass_correction_factors TO writeaccess;

