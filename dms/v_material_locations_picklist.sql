--
-- Name: v_material_locations_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_locations_picklist AS
 SELECT ml.location,
    ml.comment,
    ml.freezer,
    ml.shelf,
    ml.rack,
    ml."row",
    ml.col,
    ml.container_limit,
    ml.containers,
    ml.available
   FROM public.v_material_location_list_report ml
  WHERE ((ml.status OPERATOR(public.=) 'Active'::public.citext) AND (ml.available > 0));


ALTER TABLE public.v_material_locations_picklist OWNER TO d3l243;

--
-- Name: VIEW v_material_locations_picklist; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_material_locations_picklist IS 'Modeled after view v_material_location_list_report, but filters on available > 0';

--
-- Name: TABLE v_material_locations_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_locations_picklist TO readaccess;

