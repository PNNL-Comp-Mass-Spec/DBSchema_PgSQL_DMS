--
-- Name: v_unimod_detail_report; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_unimod_detail_report AS
 SELECT m.unimod_id,
    m.name,
    m.full_name,
    m.alternate_names,
    m.notes,
    mcf.mass_correction_tag AS dms_name,
    mcf.mass_correction_id,
    round((m.mono_mass)::numeric, 6) AS monoisotopic_mass,
    round((m.avg_mass)::numeric, 6) AS average_mass,
    m.composition,
    commonsites.sites,
    hiddensites.sites AS hidden_sites,
    m.url,
    m.date_posted,
    m.date_modified,
    m.approved,
    m.poster_username,
    m.poster_group
   FROM (((ont.t_unimod_mods m
     JOIN LATERAL ( SELECT sites.sites
           FROM ont.get_modification_site_list(m.unimod_id, 0) sites(unimod_id, sites)) commonsites ON (true))
     JOIN LATERAL ( SELECT sites.sites
           FROM ont.get_modification_site_list(m.unimod_id, 1) sites(unimod_id, sites)) hiddensites ON (true))
     LEFT JOIN public.v_mass_correction_factors mcf ON ((m.name OPERATOR(public.=) mcf.original_source_name)));


ALTER TABLE ont.v_unimod_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_unimod_detail_report; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_unimod_detail_report TO readaccess;
GRANT SELECT ON TABLE ont.v_unimod_detail_report TO writeaccess;

