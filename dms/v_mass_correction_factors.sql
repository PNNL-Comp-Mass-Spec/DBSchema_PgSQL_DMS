--
-- Name: v_mass_correction_factors; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mass_correction_factors AS
 SELECT mcf.mass_correction_id,
    mcf.mass_correction_tag,
    mcf.description,
    mcf.monoisotopic_mass,
    mcf.average_mass,
    COALESCE(mcf.empirical_formula, ''::public.citext) AS empirical_formula,
    mcf.affected_atom,
    mcf.original_source,
    mcf.original_source_name,
    m.unimod_id,
    mcf.alternative_name
   FROM (public.t_mass_correction_factors mcf
     LEFT JOIN ont.t_unimod_mods m ON (((mcf.original_source_name OPERATOR(public.=) m.name) AND (mcf.original_source OPERATOR(public.=) 'UniMod'::public.citext))));


ALTER VIEW public.v_mass_correction_factors OWNER TO d3l243;

--
-- Name: TABLE v_mass_correction_factors; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mass_correction_factors TO readaccess;
GRANT SELECT ON TABLE public.v_mass_correction_factors TO writeaccess;

