--
-- Name: v_biomaterial_list_report_2; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_biomaterial_list_report_2 AS
 SELECT b.biomaterial_id AS id,
    b.biomaterial_name AS name,
    b.source_name AS source,
    COALESCE(u_contact.name, b.contact_prn) AS contact,
    btn.biomaterial_type AS type,
    b.reason,
    b.created,
    COALESCE(u_pi.name, b.pi_prn) AS pi,
    b.comment,
    c.campaign,
    mc.container,
    ml.tag AS location,
    b.cached_organism_list AS organisms,
    b.mutation,
    b.plasmid,
    b.cell_line,
    b.material_active AS material_status
   FROM ((((((public.t_biomaterial b
     JOIN public.t_biomaterial_type_name btn ON ((b.biomaterial_type = btn.biomaterial_type_id)))
     JOIN public.t_campaign c ON ((b.campaign_id = c.campaign_id)))
     JOIN public.t_material_containers mc ON ((b.container_id = mc.container_id)))
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)))
     LEFT JOIN public.t_users u_contact ON ((b.contact_prn OPERATOR(public.=) u_contact.username)))
     LEFT JOIN public.t_users u_pi ON ((b.pi_prn OPERATOR(public.=) u_pi.username)));


ALTER TABLE public.v_biomaterial_list_report_2 OWNER TO d3l243;

--
-- Name: TABLE v_biomaterial_list_report_2; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_biomaterial_list_report_2 TO readaccess;
GRANT SELECT ON TABLE public.v_biomaterial_list_report_2 TO writeaccess;

