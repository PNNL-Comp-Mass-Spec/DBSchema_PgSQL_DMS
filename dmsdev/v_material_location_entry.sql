--
-- Name: v_material_location_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_location_entry AS
 SELECT location_id AS id,
    location,
    comment,
    status
   FROM public.t_material_locations ml;


ALTER VIEW public.v_material_location_entry OWNER TO d3l243;

--
-- Name: TABLE v_material_location_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_location_entry TO readaccess;
GRANT SELECT ON TABLE public.v_material_location_entry TO writeaccess;

