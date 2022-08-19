--
-- Name: v_mass_correction_factors_autosuggest; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mass_correction_factors_autosuggest AS
 SELECT t_mass_correction_factors.mass_correction_id AS id,
    t_mass_correction_factors.monoisotopic_mass AS value,
    ((rtrim((t_mass_correction_factors.mass_correction_tag)::text) || ' - '::text) || (t_mass_correction_factors.description)::text) AS info,
    t_mass_correction_factors.mass_correction_tag AS extra,
        CASE
            WHEN (COALESCE(t_mass_correction_factors.affected_atom, ''::bpchar) = '-'::bpchar) THEN 'std'::text
            ELSE 'iso'::text
        END AS type
   FROM public.t_mass_correction_factors
  WHERE (abs(t_mass_correction_factors.monoisotopic_mass) > (0)::double precision);


ALTER TABLE public.v_mass_correction_factors_autosuggest OWNER TO d3l243;

--
-- Name: TABLE v_mass_correction_factors_autosuggest; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mass_correction_factors_autosuggest TO readaccess;
GRANT SELECT ON TABLE public.v_mass_correction_factors_autosuggest TO writeaccess;

