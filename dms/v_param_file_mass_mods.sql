--
-- Name: v_param_file_mass_mods; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_param_file_mass_mods AS
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
    ' || Mod Type || Residue || Mod Name (DMS) || Mod Name (UniMod) || Mod Mass ||'::text AS table_code_header,
    ((((((((((' | '::text || (
        CASE pfmm.mod_type_symbol
            WHEN 'S'::bpchar THEN 'Static'::bpchar
            WHEN 'D'::bpchar THEN 'Dynamic'::bpchar
            WHEN 'T'::bpchar THEN 'Static Terminal Peptide'::bpchar
            WHEN 'P'::bpchar THEN 'Static Terminal Protein'::bpchar
            WHEN 'I'::bpchar THEN 'Isotopic'::bpchar
            ELSE pfmm.mod_type_symbol
        END)::text) || ' | '::text) || (r.description)::text) || ' | '::text) || (mcf.mass_correction_tag)::text) || ' | '::text) || (
        CASE
            WHEN (mcf.original_source OPERATOR(public.~~) '%UniMod%'::public.citext) THEN mcf.original_source_name
            ELSE ''::public.citext
        END)::text) || ' | '::text) || round((mcf.monoisotopic_mass)::numeric, 4)) || ' | '::text) AS table_code_row
   FROM ((((public.t_param_file_mass_mods pfmm
     JOIN public.t_residues r ON ((pfmm.residue_id = r.residue_id)))
     JOIN public.t_mass_correction_factors mcf ON ((pfmm.mass_correction_id = mcf.mass_correction_id)))
     JOIN public.t_seq_local_symbols_list sls ON ((pfmm.local_symbol_id = sls.local_symbol_id)))
     JOIN public.t_param_files pf ON ((pfmm.param_file_id = pf.param_file_id)));


ALTER TABLE public.v_param_file_mass_mods OWNER TO d3l243;

--
-- Name: TABLE v_param_file_mass_mods; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_param_file_mass_mods TO readaccess;

