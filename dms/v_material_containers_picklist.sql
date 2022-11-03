--
-- Name: v_material_containers_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_containers_picklist AS
 SELECT mc.container,
    mc.type,
    mc.status,
    mc.comment,
    ml.tag AS location,
    mc.sort_key
   FROM (public.t_material_containers mc
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)));


ALTER TABLE public.v_material_containers_picklist OWNER TO d3l243;

--
-- Name: TABLE v_material_containers_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_containers_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_material_containers_picklist TO writeaccess;

