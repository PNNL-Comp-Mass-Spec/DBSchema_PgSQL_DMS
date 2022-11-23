--
-- Name: v_material_container_locations; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_container_locations AS
 SELECT mc.container,
    mc.type,
    mc.status,
    mc.comment,
    mc.created,
    ml.location,
    ml.freezer_tag,
    ml.shelf,
    ml.rack,
    ml."row",
    ml.col,
    ml.location_id
   FROM (public.t_material_containers mc
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)));


ALTER TABLE public.v_material_container_locations OWNER TO d3l243;

--
-- Name: TABLE v_material_container_locations; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_container_locations TO readaccess;
GRANT SELECT ON TABLE public.v_material_container_locations TO writeaccess;

