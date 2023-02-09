--
-- Name: v_experiment_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_entry AS
 SELECT e.experiment,
    e.exp_id AS id,
    c.campaign,
    e.researcher_username,
    org.organism AS organism_name,
    e.reason,
    e.sample_concentration,
    enz.enzyme_name,
    e.lab_notebook_ref,
    e.comment,
    public.get_exp_biomaterial_list((e.experiment)::text) AS biomaterial_list,
    public.get_exp_ref_compound_list((e.experiment)::text) AS reference_compound_list,
    e.labelling,
    e.sample_prep_request_id AS sample_prep_request,
    inststd.name AS internal_standard,
    postdigestintstd.name AS postdigest_int_std,
    mc.container,
    e.wellplate,
    e.well,
    e.alkylation,
    bto.tissue,
    e.barcode
   FROM (((((((public.t_experiments e
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_enzymes enz ON ((e.enzyme_id = enz.enzyme_id)))
     JOIN public.t_internal_standards inststd ON ((e.internal_standard_id = inststd.internal_standard_id)))
     JOIN public.t_internal_standards postdigestintstd ON ((e.post_digest_internal_std_id = postdigestintstd.internal_standard_id)))
     JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)))
     JOIN public.t_material_containers mc ON ((e.container_id = mc.container_id)))
     LEFT JOIN ont.v_bto_id_to_name bto ON ((e.tissue_id OPERATOR(public.=) bto.identifier)));


ALTER TABLE public.v_experiment_entry OWNER TO d3l243;

--
-- Name: TABLE v_experiment_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_entry TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_entry TO writeaccess;

