--
-- Name: v_biomaterial_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_biomaterial_detail_report AS
 SELECT b.biomaterial_name AS name,
    b.source_name AS supplier,
        CASE
            WHEN (u_contact.name IS NULL) THEN b.contact_username
            ELSE u_contact.name_with_username
        END AS contact_usually_pnnl_staff,
    btn.biomaterial_type AS type,
    b.reason,
    b.created,
    u_pi.name_with_username AS pi,
    b.comment,
    c.campaign,
    b.biomaterial_id AS id,
    mc.container,
    ml.location,
    public.get_biomaterial_organism_list(b.biomaterial_id) AS organism_list,
    b.mutation,
    b.plasmid,
    b.cell_line,
    b.material_active AS material_status
   FROM ((((((public.t_biomaterial b
     JOIN public.t_biomaterial_type_name btn ON ((b.biomaterial_type_id = btn.biomaterial_type_id)))
     JOIN public.t_campaign c ON ((b.campaign_id = c.campaign_id)))
     JOIN public.t_material_containers mc ON ((b.container_id = mc.container_id)))
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)))
     LEFT JOIN public.t_users u_contact ON ((b.contact_username OPERATOR(public.=) u_contact.username)))
     LEFT JOIN public.t_users u_pi ON ((b.pi_username OPERATOR(public.=) u_pi.username)));


ALTER TABLE public.v_biomaterial_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_biomaterial_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_biomaterial_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_biomaterial_detail_report TO writeaccess;

