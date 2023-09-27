--
-- Name: v_data_package_biomaterial_list_report; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_biomaterial_list_report AS
 SELECT dpb.data_pkg_id AS id,
    b.biomaterial_name AS biomaterial,
    c.campaign,
    btn.biomaterial_type AS type,
    dpb.package_comment,
    b.source_name AS source,
    COALESCE(u_contact.name, b.contact_username) AS contact,
    b.reason,
    b.created,
    COALESCE(u_pi.name, b.pi_username) AS pi,
    b.comment,
    mc.container,
    ml.location,
    b.material_active AS material_status,
    b.biomaterial_id,
    dpb.item_added
   FROM (((((((dpkg.t_data_package_biomaterial dpb
     JOIN public.t_biomaterial b ON ((dpb.biomaterial_id = b.biomaterial_id)))
     JOIN public.t_biomaterial_type_name btn ON ((b.biomaterial_type = btn.biomaterial_type_id)))
     JOIN public.t_campaign c ON ((b.campaign_id = c.campaign_id)))
     JOIN public.t_material_containers mc ON ((b.container_id = mc.container_id)))
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)))
     LEFT JOIN public.t_users u_contact ON ((b.contact_username OPERATOR(public.=) u_contact.username)))
     LEFT JOIN public.t_users u_pi ON ((b.pi_username OPERATOR(public.=) u_pi.username)));


ALTER TABLE dpkg.v_data_package_biomaterial_list_report OWNER TO d3l243;

--
-- Name: TABLE v_data_package_biomaterial_list_report; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_biomaterial_list_report TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_biomaterial_list_report TO writeaccess;

