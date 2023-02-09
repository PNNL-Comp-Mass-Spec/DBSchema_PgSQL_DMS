--
-- Name: v_experiment_list_report_2; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_list_report_2 AS
 SELECT e.exp_id AS id,
    e.experiment,
    u.name_with_username AS researcher,
    t_organisms.organism,
    e.reason,
    e.comment,
    e.sample_concentration AS concentration,
    e.created,
    c.campaign,
    bto.tissue,
    cec.biomaterial_list,
    cec.reference_compound_list AS ref_compounds,
    enz.enzyme_name AS enzyme,
    e.lab_notebook_ref AS notebook,
    e.labelling,
    intstd1.name AS predigest,
    intstd2.name AS postdigest,
    e.sample_prep_request_id AS request,
    mc.container,
    ml.location,
    e.wellplate,
    e.well,
    e.alkylation AS alkylated
   FROM ((((((((((public.t_experiments e
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_users u ON ((e.researcher_username OPERATOR(public.=) u.username)))
     JOIN public.t_enzymes enz ON ((e.enzyme_id = enz.enzyme_id)))
     JOIN public.t_internal_standards intstd1 ON ((e.internal_standard_id = intstd1.internal_standard_id)))
     JOIN public.t_internal_standards intstd2 ON ((e.post_digest_internal_std_id = intstd2.internal_standard_id)))
     JOIN public.t_organisms ON ((e.organism_id = t_organisms.organism_id)))
     JOIN public.t_material_containers mc ON ((e.container_id = mc.container_id)))
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)))
     LEFT JOIN ont.v_bto_id_to_name bto ON ((e.tissue_id OPERATOR(public.=) bto.identifier)))
     LEFT JOIN public.t_cached_experiment_components cec ON ((e.exp_id = cec.exp_id)));


ALTER TABLE public.v_experiment_list_report_2 OWNER TO d3l243;

--
-- Name: TABLE v_experiment_list_report_2; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_list_report_2 TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_list_report_2 TO writeaccess;

