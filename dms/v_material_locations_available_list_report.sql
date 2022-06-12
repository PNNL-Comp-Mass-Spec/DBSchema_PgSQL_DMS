--
-- Name: v_material_locations_available_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_locations_available_list_report AS
 SELECT ml.location,
    ml.freezer,
    ml.shelf,
    ml.rack,
    ml."row",
    ml.col,
    ml.comment,
    ml.container_limit,
    ml.containers,
    ml.available,
    'New Container'::text AS action,
    ml."#id"
   FROM public.v_material_location_list_report ml
  WHERE ((ml.available > 0) AND (ml.status OPERATOR(public.=) 'Active'::public.citext));


ALTER TABLE public.v_material_locations_available_list_report OWNER TO d3l243;

--
-- Name: TABLE v_material_locations_available_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_locations_available_list_report TO readaccess;

