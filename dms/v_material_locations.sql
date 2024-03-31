--
-- Name: v_material_locations; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_locations AS
 SELECT location_id,
    freezer_tag,
    shelf,
    rack,
    "row",
    col,
    status,
    barcode,
    comment,
    container_limit,
    location
   FROM public.t_material_locations;


ALTER VIEW public.v_material_locations OWNER TO d3l243;

--
-- Name: TABLE v_material_locations; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_locations TO readaccess;
GRANT SELECT ON TABLE public.v_material_locations TO writeaccess;

