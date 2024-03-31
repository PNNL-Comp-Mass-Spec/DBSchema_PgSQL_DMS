--
-- Name: v_mass_correction_factors_autosuggest; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mass_correction_factors_autosuggest AS
 SELECT mass_correction_id AS id,
    monoisotopic_mass AS value,
    (((rtrim((mass_correction_tag)::text) || ' - '::text) || (description)::text))::public.citext AS info,
    mass_correction_tag AS extra,
        CASE
            WHEN (COALESCE(affected_atom, ''::public.citext) OPERATOR(public.=) '-'::public.citext) THEN 'std'::public.citext
            ELSE 'iso'::public.citext
        END AS type
   FROM public.t_mass_correction_factors
  WHERE (abs(monoisotopic_mass) > (0)::double precision);


ALTER VIEW public.v_mass_correction_factors_autosuggest OWNER TO d3l243;

--
-- Name: TABLE v_mass_correction_factors_autosuggest; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mass_correction_factors_autosuggest TO readaccess;
GRANT SELECT ON TABLE public.v_mass_correction_factors_autosuggest TO writeaccess;

