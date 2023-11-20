--
-- Name: v_material_items_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_items_list_report AS
 SELECT contentsq.item,
    contentsq.item_type,
    contentsq.material_id AS id,
    mc.container,
    mc.type,
    ((("substring"((contentsq.item_type)::text, 1, 1) || ':'::text) || (contentsq.material_id)::text))::public.citext AS item_id,
    ml.location,
    contentsq.material_status AS item_status,
    mc.status AS container_status,
    contentsq.request_id AS prep_request,
    contentsq.campaign
   FROM ((public.t_material_containers mc
     JOIN ( SELECT e.experiment AS item,
            'Experiment'::public.citext AS item_type,
            e.container_id,
            e.exp_id AS material_id,
            e.sample_prep_request_id AS request_id,
            e.material_active AS material_status,
            c.campaign
           FROM (public.t_experiments e
             JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
        UNION
         SELECT b.biomaterial_name AS item,
            'Biomaterial'::public.citext AS item_type,
            b.container_id,
            b.biomaterial_id AS material_id,
            NULL::integer AS request_id,
            b.material_active AS material_status,
            c.campaign
           FROM (public.t_biomaterial b
             JOIN public.t_campaign c ON ((b.campaign_id = c.campaign_id)))
        UNION
         SELECT rc.compound_name AS item,
            'RefCompound'::public.citext AS item_type,
            rc.container_id,
            rc.compound_id AS material_id,
            NULL::integer AS request_id,
                CASE
                    WHEN (rc.active > 0) THEN 'Active'::public.citext
                    ELSE 'Inactive'::public.citext
                END AS material_status,
            c.campaign
           FROM (public.t_reference_compound rc
             JOIN public.t_campaign c ON ((rc.campaign_id = c.campaign_id)))) contentsq ON ((contentsq.container_id = mc.container_id)))
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)));


ALTER TABLE public.v_material_items_list_report OWNER TO d3l243;

--
-- Name: TABLE v_material_items_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_items_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_material_items_list_report TO writeaccess;

