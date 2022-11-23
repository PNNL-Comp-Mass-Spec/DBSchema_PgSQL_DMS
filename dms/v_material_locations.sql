--
-- Name: v_material_locations; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_locations AS
 SELECT t_material_locations.location_id,
    t_material_locations.freezer_tag,
    t_material_locations.shelf,
    t_material_locations.rack,
    t_material_locations."row",
    t_material_locations.col,
    t_material_locations.status,
    t_material_locations.barcode,
    t_material_locations.comment,
    t_material_locations.container_limit,
    t_material_locations.location
   FROM public.t_material_locations;


ALTER TABLE public.v_material_locations OWNER TO d3l243;

--
-- Name: TABLE v_material_locations; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_locations TO readaccess;
GRANT SELECT ON TABLE public.v_material_locations TO writeaccess;

