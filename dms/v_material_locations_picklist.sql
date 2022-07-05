--
-- Name: v_material_locations_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_locations_picklist AS
 SELECT ml.tag AS location,
    ml.comment,
    f.freezer,
    ml.shelf,
    ml.rack,
    ml."row",
    ml.col,
    ml.container_limit,
    count(mc.location_id) AS containers,
    (ml.container_limit - count(mc.location_id)) AS available
   FROM ((public.t_material_locations ml
     JOIN public.t_material_freezers f ON ((ml.freezer_tag OPERATOR(public.=) f.freezer_tag)))
     LEFT JOIN public.t_material_containers mc ON ((ml.location_id = mc.location_id)))
  WHERE (ml.status OPERATOR(public.=) 'Active'::public.citext)
  GROUP BY ml.location_id, f.freezer, ml.shelf, ml.rack, ml."row", ml.comment, ml.tag, ml.col, ml.status, ml.container_limit
 HAVING ((ml.container_limit - count(mc.location_id)) > 0);


ALTER TABLE public.v_material_locations_picklist OWNER TO d3l243;

--
-- Name: VIEW v_material_locations_picklist; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_material_locations_picklist IS 'Modeled after view v_material_location_list_report, but filters on available > 0';

--
-- Name: TABLE v_material_locations_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_locations_picklist TO readaccess;

