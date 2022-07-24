--
-- Name: v_param_file_mass_mods_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_param_file_mass_mods_list_report AS
 SELECT pfmm.mod_entry_id,
    pfmm.param_file_id,
    pfmm.mod_type_symbol AS mod_type,
    r.residue_symbol AS residue,
    r.description AS residue_desc,
    sls.local_symbol AS symbol,
    pfmm.mass_correction_id AS mod_id,
    mcf.mass_correction_tag,
    mcf.monoisotopic_mass AS mono_mass,
    mcf.description AS mod_description,
    COALESCE(mcf.empirical_formula, ''::public.citext) AS empirical_formula,
    mcf.original_source,
    mcf.original_source_name,
    pf.param_file_name,
    pf.param_file_description,
    tool.analysis_tool AS primary_tool
   FROM ((((((public.t_param_file_mass_mods pfmm
     JOIN public.t_residues r ON ((pfmm.residue_id = r.residue_id)))
     JOIN public.t_mass_correction_factors mcf ON ((pfmm.mass_correction_id = mcf.mass_correction_id)))
     JOIN public.t_seq_local_symbols_list sls ON ((pfmm.local_symbol_id = sls.local_symbol_id)))
     JOIN public.t_param_files pf ON ((pfmm.param_file_id = pf.param_file_id)))
     JOIN public.t_param_file_types pft ON ((pf.param_file_type_id = pft.param_file_type_id)))
     JOIN public.t_analysis_tool tool ON ((pft.primary_tool_id = tool.analysis_tool_id)));


ALTER TABLE public.v_param_file_mass_mods_list_report OWNER TO d3l243;

--
-- Name: TABLE v_param_file_mass_mods_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_param_file_mass_mods_list_report TO readaccess;

