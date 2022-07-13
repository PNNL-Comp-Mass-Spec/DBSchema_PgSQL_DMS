--
-- Name: v_experiment_metadata; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_metadata AS
 SELECT e.experiment AS name,
    e.exp_id AS id,
    u.name_with_username AS researcher,
    org.organism,
    e.reason AS reason_for_experiment,
    e.comment,
    e.created,
    e.sample_concentration,
    enz.enzyme_name AS digestion_enzyme,
    e.lab_notebook_ref AS lab_notebook,
    c.campaign,
    cec.biomaterial_list AS cell_cultures,
    cec.reference_compound_list AS ref_compounds,
    e.labelling,
    intstd1.name AS predigest_int_std,
    intstd2.name AS postdigest_int_std,
    e.sample_prep_request_id AS request
   FROM (((((((public.t_experiments e
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_users u ON ((e.researcher_prn OPERATOR(public.=) u.username)))
     JOIN public.t_enzymes enz ON ((e.enzyme_id = enz.enzyme_id)))
     JOIN public.t_internal_standards intstd1 ON ((e.internal_standard_id = intstd1.internal_standard_id)))
     JOIN public.t_internal_standards intstd2 ON ((e.post_digest_internal_std_id = intstd2.internal_standard_id)))
     JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)))
     LEFT JOIN public.t_cached_experiment_components cec ON ((e.exp_id = cec.exp_id)));


ALTER TABLE public.v_experiment_metadata OWNER TO d3l243;

--
-- Name: TABLE v_experiment_metadata; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_metadata TO readaccess;

