--
-- Name: v_material_container_item_stats; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_container_item_stats AS
 SELECT mc.container,
    mc.type,
    ml.tag AS location,
    (count(contentsq.material_id))::integer AS items,
    mc.comment,
    mc.status,
    mc.created,
    mc.container_id,
    mc.researcher
   FROM ((public.t_material_containers mc
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)))
     LEFT JOIN ( SELECT t_biomaterial.container_id,
            t_biomaterial.biomaterial_id AS material_id
           FROM public.t_biomaterial
          WHERE (t_biomaterial.material_active OPERATOR(public.=) 'Active'::public.citext)
        UNION
         SELECT t_experiments.container_id,
            t_experiments.exp_id AS material_id
           FROM public.t_experiments
          WHERE (t_experiments.material_active OPERATOR(public.=) 'Active'::public.citext)
        UNION
         SELECT t_reference_compound.container_id,
            t_reference_compound.compound_id AS material_id
           FROM public.t_reference_compound
          WHERE (t_reference_compound.active > 0)) contentsq ON ((contentsq.container_id = mc.container_id)))
  GROUP BY mc.container, mc.type, ml.tag, mc.comment, mc.created, mc.status, mc.container_id, mc.researcher;


ALTER TABLE public.v_material_container_item_stats OWNER TO d3l243;

--
-- Name: TABLE v_material_container_item_stats; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_container_item_stats TO readaccess;
GRANT SELECT ON TABLE public.v_material_container_item_stats TO writeaccess;

