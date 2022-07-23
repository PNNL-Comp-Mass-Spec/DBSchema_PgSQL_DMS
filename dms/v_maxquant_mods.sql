--
-- Name: v_maxquant_mods; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_maxquant_mods AS
 SELECT modinfo.mod_id,
    modinfo.mod_title,
    modinfo.mod_position,
    modinfo.composition,
    modinfo.mass_correction_id,
    mcf.mass_correction_tag
   FROM (public.t_maxquant_mods modinfo
     LEFT JOIN public.t_mass_correction_factors mcf ON ((modinfo.mass_correction_id = mcf.mass_correction_id)));


ALTER TABLE public.v_maxquant_mods OWNER TO d3l243;

--
-- Name: TABLE v_maxquant_mods; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_maxquant_mods TO readaccess;

