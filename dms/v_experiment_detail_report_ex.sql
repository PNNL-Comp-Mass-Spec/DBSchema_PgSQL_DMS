--
-- Name: v_experiment_detail_report_ex; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_detail_report_ex AS
 SELECT e.experiment,
    u.name_with_username AS researcher,
    org.organism,
    e.reason AS reason_for_experiment,
    e.comment,
    e.created,
    e.sample_concentration,
    enz.enzyme_name AS digestion_enzyme,
    e.lab_notebook_ref AS lab_notebook,
    c.campaign,
    bto.term_name AS plant_or_animal_tissue,
    cec.biomaterial_list,
    cec.reference_compound_list AS reference_compounds,
    e.labelling,
    intstdpre.name AS predigest_int_std,
    intstdpost.name AS postdigest_int_std,
    e.alkylation AS alkylated,
    e.sample_prep_request_id AS request,
    bto.identifier AS tissue_id,
    public.get_experiment_group_list(e.exp_id) AS experiment_groups,
    COALESCE((ces.dataset_count)::bigint, (0)::bigint) AS datasets,
    ces.most_recent_dataset,
    COALESCE((ces.factor_count)::bigint, (0)::bigint) AS factors,
    COALESCE(expfilecount.filecount, (0)::bigint) AS experiment_files,
    COALESCE(expgroupfilecount.filecount, (0)::bigint) AS experiment_group_files,
    e.exp_id AS id,
    mc.container,
    ml.location,
    e.material_active AS material_status,
    e.last_used,
    e.wellplate,
    e.well,
    e.barcode
   FROM (((((((((((((public.t_experiments e
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_users u ON ((e.researcher_username OPERATOR(public.=) u.username)))
     JOIN public.t_enzymes enz ON ((e.enzyme_id = enz.enzyme_id)))
     JOIN public.t_internal_standards intstdpre ON ((e.internal_standard_id = intstdpre.internal_standard_id)))
     JOIN public.t_internal_standards intstdpost ON ((e.post_digest_internal_std_id = intstdpost.internal_standard_id)))
     JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)))
     JOIN public.t_material_containers mc ON ((e.container_id = mc.container_id)))
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)))
     LEFT JOIN public.t_cached_experiment_stats ces ON ((ces.exp_id = e.exp_id)))
     LEFT JOIN ( SELECT t_file_attachment.entity_id,
            count(t_file_attachment.attachment_id) AS filecount
           FROM public.t_file_attachment
          WHERE ((t_file_attachment.entity_type OPERATOR(public.=) 'experiment'::public.citext) AND (t_file_attachment.active > 0))
          GROUP BY t_file_attachment.entity_id) expfilecount ON ((expfilecount.entity_id OPERATOR(public.=) e.experiment)))
     LEFT JOIN ( SELECT egm.exp_id,
            egm.group_id,
            fa.filecount
           FROM ((public.t_experiment_group_members egm
             JOIN public.t_experiment_groups eg ON ((egm.group_id = eg.group_id)))
             JOIN ( SELECT t_file_attachment.entity_id,
                    count(t_file_attachment.attachment_id) AS filecount
                   FROM public.t_file_attachment
                  WHERE ((t_file_attachment.entity_type OPERATOR(public.=) 'experiment_group'::public.citext) AND (t_file_attachment.active > 0))
                  GROUP BY t_file_attachment.entity_id) fa ON ((eg.group_id = (fa.entity_id)::integer)))) expgroupfilecount ON ((expgroupfilecount.exp_id = e.exp_id)))
     LEFT JOIN ont.t_cv_bto_cached_names bto ON ((e.tissue_id OPERATOR(public.=) bto.identifier)))
     LEFT JOIN public.t_cached_experiment_components cec ON ((e.exp_id = cec.exp_id)));


ALTER VIEW public.v_experiment_detail_report_ex OWNER TO d3l243;

--
-- Name: TABLE v_experiment_detail_report_ex; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_detail_report_ex TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_detail_report_ex TO writeaccess;

