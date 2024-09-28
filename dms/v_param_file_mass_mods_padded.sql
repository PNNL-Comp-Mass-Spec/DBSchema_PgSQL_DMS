--
-- Name: v_param_file_mass_mods_padded; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_param_file_mass_mods_padded AS
 SELECT pfmm.mod_entry_id,
    pfmm.residue_id,
    pfmm.local_symbol_id,
    pfmm.mass_correction_id,
    pfmm.param_file_id,
    pfmm.mod_type_symbol,
    pfmm.maxquant_mod_id,
    r.residue_symbol,
    mcf.mass_correction_tag,
    mcf.monoisotopic_mass,
    sls.local_symbol,
    r.description AS residue_desc,
    pf.param_file_name,
    pf.param_file_description,
    '|| Mod Type               || Residue           || Mod Name (DMS)    || Mod Name (UniMod) || Mod Mass ||'::text AS table_code_header,
    ((((((((((((((((((((((((((((' | '::public.citext)::text || (
        CASE pfmm.mod_type_symbol
            WHEN 'S'::bpchar THEN 'Static                 '::public.citext
            WHEN 'D'::bpchar THEN 'Dynamic                '::public.citext
            WHEN 'T'::bpchar THEN 'Static Terminal Peptide'::public.citext
            WHEN 'P'::bpchar THEN 'Static Terminal Protein'::public.citext
            WHEN 'I'::bpchar THEN 'Isotopic               '::public.citext
            ELSE (pfmm.mod_type_symbol)::public.citext
        END)::text))::public.citext)::text || (' | '::public.citext)::text))::public.citext)::text || GREATEST((r.description)::text, rpad((r.description)::text, 18))))::public.citext)::text || (' | '::public.citext)::text))::public.citext)::text || GREATEST((mcf.mass_correction_tag)::text, rpad((mcf.mass_correction_tag)::text, 18))))::public.citext)::text || (' | '::public.citext)::text))::public.citext)::text ||
        CASE
            WHEN (mcf.original_source OPERATOR(public.~~) '%UniMod%'::public.citext) THEN GREATEST((mcf.original_source_name)::text, rpad((mcf.original_source_name)::text, 18))
            ELSE (''::public.citext)::text
        END))::public.citext)::text || (' | '::public.citext)::text))::public.citext)::text || round((mcf.monoisotopic_mass)::numeric, 4)) || (
        CASE
            WHEN (mcf.monoisotopic_mass < (100)::double precision) THEN ' '::text
            ELSE ''::text
        END || ('  | '::public.citext)::text)))::public.citext AS table_code_row
   FROM ((((public.t_param_file_mass_mods pfmm
     JOIN public.t_residues r ON ((pfmm.residue_id = r.residue_id)))
     JOIN public.t_mass_correction_factors mcf ON ((pfmm.mass_correction_id = mcf.mass_correction_id)))
     JOIN public.t_seq_local_symbols_list sls ON ((pfmm.local_symbol_id = sls.local_symbol_id)))
     JOIN public.t_param_files pf ON ((pfmm.param_file_id = pf.param_file_id)));


ALTER VIEW public.v_param_file_mass_mods_padded OWNER TO d3l243;

--
-- Name: TABLE v_param_file_mass_mods_padded; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_param_file_mass_mods_padded TO readaccess;
GRANT SELECT ON TABLE public.v_param_file_mass_mods_padded TO writeaccess;

