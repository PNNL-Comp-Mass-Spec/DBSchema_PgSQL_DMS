--
-- Name: v_param_file_mass_mod_info; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_param_file_mass_mod_info AS
 SELECT pf.param_file_name,
    pfmm.param_file_id,
    s.local_symbol,
    pfmm.local_symbol_id,
    pfmm.mod_type_symbol,
    r.residue_symbol,
    mcf.affected_atom,
    pfmm.mass_correction_id,
    mcf.mass_correction_tag,
    mcf.description,
    mcf.monoisotopic_mass,
    COALESCE(mcf.empirical_formula, ''::public.citext) AS empirical_formula,
    COALESCE(mqm.mod_title, ''::public.citext) AS maxquant_mod_name,
        CASE
            WHEN (mcf.original_source OPERATOR(public.=) 'UniMod'::public.citext) THEN mcf.original_source_name
            ELSE ''::public.citext
        END AS unimod_mod_name,
    ((((((((((((((((((
        CASE pfmm.mod_type_symbol
            WHEN 'D'::bpchar THEN 'Dyn'::public.citext
            WHEN 'S'::bpchar THEN 'Stat'::public.citext
            WHEN 'T'::bpchar THEN 'PepTerm'::public.citext
            WHEN 'P'::bpchar THEN 'ProtTerm'::public.citext
            WHEN 'I'::bpchar THEN 'Iso'::public.citext
            ELSE (pfmm.mod_type_symbol)::public.citext
        END)::text || ('_'::public.citext)::text))::public.citext)::text || (r.abbreviation)::text))::public.citext)::text || ('_'::public.citext)::text))::public.citext)::text || (mcf.mass_correction_tag)::text))::public.citext)::text || ('_'::public.citext)::text))::public.citext)::text || (mcf.original_source_name)::text))::public.citext AS mod_code,
    ((((((((((((((((((((((((
        CASE pfmm.mod_type_symbol
            WHEN 'D'::bpchar THEN 'Dyn'::public.citext
            WHEN 'S'::bpchar THEN 'Stat'::public.citext
            WHEN 'T'::bpchar THEN 'PepTerm'::public.citext
            WHEN 'P'::bpchar THEN 'ProtTerm'::public.citext
            WHEN 'I'::bpchar THEN 'Iso'::public.citext
            ELSE (pfmm.mod_type_symbol)::public.citext
        END)::text || ('_'::public.citext)::text))::public.citext)::text || (r.abbreviation)::text))::public.citext)::text || ('_'::public.citext)::text))::public.citext)::text || (mcf.mass_correction_tag)::text))::public.citext)::text || ('_'::public.citext)::text))::public.citext)::text || (mcf.original_source_name)::text))::public.citext)::text || ('_'::public.citext)::text))::public.citext)::text || ((s.local_symbol)::public.citext)::text))::public.citext AS mod_code_with_symbol
   FROM (((((public.t_mass_correction_factors mcf
     JOIN public.t_param_file_mass_mods pfmm ON ((mcf.mass_correction_id = pfmm.mass_correction_id)))
     JOIN public.t_residues r ON ((pfmm.residue_id = r.residue_id)))
     JOIN public.t_seq_local_symbols_list s ON ((pfmm.local_symbol_id = s.local_symbol_id)))
     JOIN public.t_param_files pf ON ((pfmm.param_file_id = pf.param_file_id)))
     LEFT JOIN public.t_maxquant_mods mqm ON ((mqm.mod_id = pfmm.maxquant_mod_id)));


ALTER TABLE public.v_param_file_mass_mod_info OWNER TO d3l243;

--
-- Name: TABLE v_param_file_mass_mod_info; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_param_file_mass_mod_info TO readaccess;
GRANT SELECT ON TABLE public.v_param_file_mass_mod_info TO writeaccess;

