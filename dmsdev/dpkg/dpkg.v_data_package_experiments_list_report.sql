--
-- Name: v_data_package_experiments_list_report; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_experiments_list_report AS
 SELECT dpe.data_pkg_id AS id,
    e.experiment,
    c.campaign,
    dpe.package_comment,
    u.name_with_username AS researcher,
    t_organisms.organism,
    e.reason,
    e.comment,
    e.sample_concentration AS concentration,
    e.created,
    cec.biomaterial_list,
    bto.term_name AS tissue,
    enz.enzyme_name AS enzyme,
    e.labelling,
    intstd1.name AS predigest,
    intstd2.name AS postdigest,
    e.sample_prep_request_id AS request,
    dpe.item_added
   FROM (((((((((dpkg.t_data_package_experiments dpe
     JOIN public.t_experiments e ON ((e.exp_id = dpe.experiment_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_users u ON ((e.researcher_username OPERATOR(public.=) u.username)))
     JOIN public.t_enzymes enz ON ((e.enzyme_id = enz.enzyme_id)))
     JOIN public.t_internal_standards intstd1 ON ((e.internal_standard_id = intstd1.internal_standard_id)))
     JOIN public.t_internal_standards intstd2 ON ((e.post_digest_internal_std_id = intstd2.internal_standard_id)))
     JOIN public.t_organisms ON ((e.organism_id = t_organisms.organism_id)))
     LEFT JOIN ont.t_cv_bto_cached_names bto ON ((e.tissue_id OPERATOR(public.=) bto.identifier)))
     LEFT JOIN public.t_cached_experiment_components cec ON ((e.exp_id = cec.exp_id)));


ALTER VIEW dpkg.v_data_package_experiments_list_report OWNER TO d3l243;

--
-- Name: TABLE v_data_package_experiments_list_report; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_experiments_list_report TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_experiments_list_report TO writeaccess;

