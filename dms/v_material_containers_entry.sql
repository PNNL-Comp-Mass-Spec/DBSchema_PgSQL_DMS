--
-- Name: v_material_containers_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_containers_entry AS
 SELECT mc.container,
    mc.type,
    ml.tag AS location,
    mc.status,
    mc.comment,
    mc.barcode,
    mc.researcher
   FROM (public.t_material_containers mc
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)));


ALTER TABLE public.v_material_containers_entry OWNER TO d3l243;

--
-- Name: TABLE v_material_containers_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_containers_entry TO readaccess;

