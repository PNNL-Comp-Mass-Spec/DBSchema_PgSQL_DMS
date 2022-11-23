--
-- Name: v_material_move_items_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_move_items_list_report AS
 SELECT contentsq.item,
    contentsq.item_type,
    contentsq.material_id AS id,
    mc.container,
    mc.type,
    (("substring"(contentsq.item_type, 1, 1) || ':'::text) || (contentsq.material_id)::text) AS item_id,
    ml.location,
    mc.status AS container_status,
    contentsq.request_id AS prep_request
   FROM ((public.t_material_containers mc
     JOIN ( SELECT t_experiments.experiment AS item,
            'Experiment'::text AS item_type,
            t_experiments.container_id,
            t_experiments.exp_id AS material_id,
            t_experiments.sample_prep_request_id AS request_id
           FROM public.t_experiments
          WHERE (t_experiments.material_active OPERATOR(public.=) 'Active'::public.citext)
        UNION
         SELECT t_biomaterial.biomaterial_name AS item,
            'Biomaterial'::text AS item_type,
            t_biomaterial.container_id,
            t_biomaterial.biomaterial_id AS material_id,
            NULL::integer AS request_id
           FROM public.t_biomaterial
          WHERE (t_biomaterial.material_active OPERATOR(public.=) 'Active'::public.citext)
        UNION
         SELECT t_reference_compound.compound_name AS item,
            'RefCompound'::text AS item_type,
            t_reference_compound.container_id,
            t_reference_compound.compound_id AS material_id,
            NULL::integer AS request_id
           FROM public.t_reference_compound
          WHERE (t_reference_compound.active > 0)) contentsq ON ((contentsq.container_id = mc.container_id)))
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)));


ALTER TABLE public.v_material_move_items_list_report OWNER TO d3l243;

--
-- Name: VIEW v_material_move_items_list_report; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_material_move_items_list_report IS 'This view shows active items in containers';

--
-- Name: TABLE v_material_move_items_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_move_items_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_material_move_items_list_report TO writeaccess;

