--
-- Name: v_reference_compound_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_reference_compound_detail_report AS
 SELECT rc.compound_id,
    rc.compound_name,
    rc.description,
    rct.compound_type_name AS compound_type,
    rc.gene_name AS gene_or_protein,
    rc.modifications,
    org.organism,
    rc.pub_chem_cid,
        CASE
            WHEN (u.name IS NULL) THEN rc.contact_prn
            ELSE u.name_with_username
        END AS contact,
    rc.created,
    c.campaign,
    mc.container,
    ml.location,
    rc.wellplate_name AS wellplate,
    rc.well_number AS well,
    rc.supplier,
    rc.product_id,
    rc.purchase_date,
    rc.purity,
    rc.purchase_quantity,
    rc.mass,
    yn.description AS active
   FROM (((((((public.t_reference_compound rc
     JOIN public.t_campaign c ON ((rc.campaign_id = c.campaign_id)))
     JOIN public.t_reference_compound_type_name rct ON ((rc.compound_type_id = rct.compound_type_id)))
     JOIN public.t_organisms org ON ((rc.organism_id = org.organism_id)))
     JOIN public.t_material_containers mc ON ((rc.container_id = mc.container_id)))
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)))
     JOIN public.t_yes_no yn ON ((rc.active = yn.flag)))
     LEFT JOIN public.t_users u ON ((rc.contact_prn OPERATOR(public.=) u.username)));


ALTER TABLE public.v_reference_compound_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_reference_compound_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_reference_compound_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_reference_compound_detail_report TO writeaccess;

