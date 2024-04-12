--
-- Name: v_material_move_containers_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_move_containers_list_report AS
 SELECT mc.container,
    ''::text AS sel,
    mc.type,
    ml.location,
    count(contentsq.material_id) AS items,
    mc.comment,
    mc.created,
    mc.container_id AS id
   FROM ((public.t_material_containers mc
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)))
     LEFT JOIN ( SELECT t_biomaterial.container_id,
            t_biomaterial.biomaterial_id AS material_id
           FROM public.t_biomaterial
        UNION
         SELECT t_experiments.container_id,
            t_experiments.exp_id AS material_id
           FROM public.t_experiments
        UNION
         SELECT t_reference_compound.container_id,
            t_reference_compound.compound_id AS material_id
           FROM public.t_reference_compound) contentsq ON ((contentsq.container_id = mc.container_id)))
  WHERE (mc.status OPERATOR(public.=) 'Active'::public.citext)
  GROUP BY mc.container, mc.type, ml.location, mc.comment, mc.created, mc.status, mc.container_id;


ALTER VIEW public.v_material_move_containers_list_report OWNER TO d3l243;

--
-- Name: TABLE v_material_move_containers_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_move_containers_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_material_move_containers_list_report TO writeaccess;

