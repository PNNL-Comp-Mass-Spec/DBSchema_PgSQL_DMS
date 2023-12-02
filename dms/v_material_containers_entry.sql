--
-- Name: v_material_containers_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_containers_entry AS
 SELECT mc.container,
    mc.type,
    ml.location,
    mc.status,
    mc.comment,
    c.campaign,
    mc.researcher
   FROM ((public.t_material_containers mc
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)))
     LEFT JOIN public.t_campaign c ON ((mc.campaign_id = c.campaign_id)));


ALTER VIEW public.v_material_containers_entry OWNER TO d3l243;

--
-- Name: TABLE v_material_containers_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_containers_entry TO readaccess;
GRANT SELECT ON TABLE public.v_material_containers_entry TO writeaccess;

