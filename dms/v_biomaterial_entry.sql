--
-- Name: v_biomaterial_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_biomaterial_entry AS
 SELECT b.biomaterial_name AS name,
    b.source_name,
    b.contact_username,
    b.pi_username,
    btn.biomaterial_type AS biomaterial_type_name,
    b.reason,
    b.comment,
    c.campaign,
    mc.container,
    public.get_biomaterial_organism_list(b.biomaterial_id) AS organism_list,
    b.mutation,
    b.plasmid,
    b.cell_line
   FROM (((public.t_biomaterial b
     JOIN public.t_biomaterial_type_name btn ON ((b.biomaterial_type_id = btn.biomaterial_type_id)))
     JOIN public.t_campaign c ON ((b.campaign_id = c.campaign_id)))
     JOIN public.t_material_containers mc ON ((b.container_id = mc.container_id)));


ALTER VIEW public.v_biomaterial_entry OWNER TO d3l243;

--
-- Name: TABLE v_biomaterial_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_biomaterial_entry TO readaccess;
GRANT SELECT ON TABLE public.v_biomaterial_entry TO writeaccess;

