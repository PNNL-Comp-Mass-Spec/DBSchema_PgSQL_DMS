--
-- Name: v_material_location_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_location_list_report AS
 SELECT ml.location,
    f.freezer,
    ml.shelf,
    ml.rack,
    ml."row",
    ml.col,
    ml.comment,
    ml.container_limit,
    count(mc.location_id) AS containers,
    (ml.container_limit - count(mc.location_id)) AS available,
    ml.status,
    ml.location_id AS id
   FROM ((public.t_material_locations ml
     JOIN public.t_material_freezers f ON ((ml.freezer_tag OPERATOR(public.=) f.freezer_tag)))
     LEFT JOIN public.t_material_containers mc ON ((ml.location_id = mc.location_id)))
  GROUP BY ml.location_id, f.freezer, ml.shelf, ml.rack, ml."row", ml.comment, ml.location, ml.col, ml.status, ml.container_limit;


ALTER TABLE public.v_material_location_list_report OWNER TO d3l243;

--
-- Name: TABLE v_material_location_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_location_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_material_location_list_report TO writeaccess;

