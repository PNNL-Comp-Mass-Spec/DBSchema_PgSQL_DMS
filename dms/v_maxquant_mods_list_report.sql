--
-- Name: v_maxquant_mods_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_maxquant_mods_list_report AS
 SELECT modinfo.mod_id AS id,
    modinfo.mod_title,
    modinfo.mod_position,
    r.residue_symbol,
    r.residue_id,
    mcf.mass_correction_id AS mod_id,
    mcf.mass_correction_tag
   FROM (((public.t_maxquant_mod_residues modresidues
     JOIN public.t_maxquant_mods modinfo ON ((modresidues.mod_id = modinfo.mod_id)))
     JOIN public.t_residues r ON ((modresidues.residue_id = r.residue_id)))
     LEFT JOIN public.t_mass_correction_factors mcf ON ((modinfo.mass_correction_id = mcf.mass_correction_id)));


ALTER TABLE public.v_maxquant_mods_list_report OWNER TO d3l243;

--
-- Name: TABLE v_maxquant_mods_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_maxquant_mods_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_maxquant_mods_list_report TO writeaccess;

