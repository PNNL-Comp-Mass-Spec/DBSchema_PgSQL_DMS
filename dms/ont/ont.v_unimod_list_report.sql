--
-- Name: v_unimod_list_report; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_unimod_list_report AS
 SELECT m.unimod_id AS id,
    m.name,
    mcf.mass_correction_tag AS dms_name,
    round((m.mono_mass)::numeric, 6) AS mono_mass,
    m.full_name,
    m.alternate_names,
    m.composition,
    commonsites.sites,
    (m.date_posted)::date AS posted,
    (m.date_modified)::date AS modified,
    m.approved
   FROM ((ont.t_unimod_mods m
     JOIN LATERAL ( SELECT sites.sites
           FROM ont.get_modification_site_list(m.unimod_id, 0) sites(unimod_id, sites)) commonsites ON (true))
     LEFT JOIN public.v_mass_correction_factors mcf ON ((m.name OPERATOR(public.=) mcf.original_source_name)));


ALTER TABLE ont.v_unimod_list_report OWNER TO d3l243;

--
-- Name: TABLE v_unimod_list_report; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_unimod_list_report TO readaccess;
GRANT SELECT ON TABLE ont.v_unimod_list_report TO writeaccess;

